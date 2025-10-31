const express = require('express');
const router = express.Router();
const db = require('./db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const fsPromises = fs.promises;
const bcrypt = require('bcryptjs');

// Add JSON body parser middleware
router.use(express.json());
router.use(express.urlencoded({ extended: true }));

// Add CORS middleware
router.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});



// Define the directory where uploaded images are stored
const uploadDirectory = path.join(__dirname, 'uploads');

// Multer storage configuration
const storage = multer.diskStorage({
    destination: function(req, file, cb) {
        cb(null, uploadDirectory); // Define the destination folder
    },
    filename: function(req, file, cb) {
        // Define the file name (you can modify this according to your needs)
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({ storage: storage });

// Serve static files from the 'uploads' directory
router.use('/uploads', express.static(uploadDirectory));

// Route to add/upload a profile picture

// POST: upload profile picture
router.post('/profile-picture/:userId', upload.single('profileImage'), async (req, res) => {
    try {
      const { userId } = req.params;
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
  
      const filename = req.file.filename;
      await db.updateUserFilename(userId, filename); // persist filename in DB column (e.g., 'filename')
  
      res.status(200).json({ message: 'Profile picture uploaded', filename });
    } catch (err) {
      console.error('Upload error:', err);
      res.status(500).json({ error: 'Failed to upload profile picture' });
    }
  });


router.post('/add', upload.single('profilePicture'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
    }

    const filename = req.file.filename; // Get the filename
    const userId = req.body.userId; // Get the userId from the request body

    // Check if the user ID is provided
    if (!userId) {
        return res.status(400).json({ error: "User ID is required" });
    }

    
    const updateQuery = "UPDATE profile_picture SET filename = ? WHERE userId = ?";
    db.query(updateQuery, [filename, userId], (err, result) => {
        if (err) {
            console.error("Database error:", err);
            return res.status(500).json({ error: "Internal server error" });
        }

        console.log("Profile picture updated successfully:", userId);
        res.status(200).json({ message: "Profile picture updated successfully" });
    });
});



// Route to search for a profile picture by user email and password

router.get('/search', async (req, res) => {
    const userEmail = req.query.userEmail;
    const password = req.query.password;
    const companyId = req.query.companyId; // Required: which company app is the user logging into
    const branchId = req.query.branchId; // Optional: specific branch within the company

    if (!userEmail || !password || !companyId) {
        console.log("User email, password, and companyId are required.", userEmail, password, companyId);
        return res.status(400).json({ error: 'User email, password, and companyId are required.' });
    }

    // Fetch the user data including the hashed password from the database
    const sql = "SELECT * FROM profile_picture WHERE userEmail = ?";
    db.query(sql, [userEmail], async (err, data) => {
        if (err) {
            console.error('Error fetching profile picture:', err);
            return res.status(500).json({ error: 'An error occurred, please try again' });
        }
        if (data.length === 0) {
            return res.status(404).json({ error: 'Invalid username or password' });
        }

        const user = data[0];

        // Validate company access - user must belong to the specified company
        if (parseInt(user.companyId) !== parseInt(companyId)) {
            console.log(`Company access denied for user ${userEmail}: user belongs to company ${user.companyId}, attempting login to company ${companyId}`);
            return res.status(403).json({ error: 'Access denied. User does not belong to this company.' });
        }

        // Validate branch access if branchId is specified
        if (branchId) {
            if (user.branch_id === null) {
                console.log(`Branch access denied for user ${userEmail}: user has no branch assignment, attempting login to branch ${branchId}`);
                return res.status(403).json({ error: 'Access denied. User is not assigned to any branch.' });
            }
            if (parseInt(user.branch_id) !== parseInt(branchId)) {
                console.log(`Branch access denied for user ${userEmail}: user belongs to branch ${user.branch_id}, attempting login to branch ${branchId}`);
                return res.status(403).json({ error: 'Access denied. User does not belong to this branch.' });
            }
        }

        // Get the stored hashed password
        const storedHashedPassword = user.password;

        // Compare the provided password with the stored hashed password
        try {
            const isMatch = await bcrypt.compare(password, storedHashedPassword);
            if (isMatch) {
                // Remove sensitive data before returning
                const { password: _, ...userData } = user;
                return res.json([{
                    ...userData,
                    loginCompanyId: companyId,
                    loginBranchId: branchId || null
                }]);
            } else {
                return res.status(401).json({ error: 'Invalid username or password' });
            }
        } catch (error) {
            console.error('Error comparing passwords:', error);
            return res.status(500).json({ error: 'An error occurred, please try again' });
        }
    });
});

router.get('/user/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional: filter by specific branch

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required to search users' });
    }

    let sql = "SELECT userId, userName, userEmail, companyName, companyId, phoneNumber, bloodGroup, user_role, branch_id, filename FROM profile_picture WHERE companyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) {
            console.error('Error fetching users:', err);
            return res.status(500).json({ error: 'Error fetching users' });
        }
        return res.json(data);
    });
});

// Delete a user by ID
// Update user by ID
router.put('/user/update/:id', (req, res) => {
    const userId = req.params.id;
    const updateData = req.body;
    const companyId = req.query.companyId; // Required for security validation

    console.log('Updating user ID:', userId);
    console.log('Update data:', updateData);
    console.log('Company ID:', companyId);

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required for user updates.' });
    }

    // Check if user exists and belongs to the specified company
    const checkUserQuery = 'SELECT * FROM profile_picture WHERE userId = ? AND companyId = ?';
    db.query(checkUserQuery, [userId, companyId], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: 'Database error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'User not found or access denied.' });
        }

        const existingUser = results[0];

        // Prepare update fields and values
        const updateFields = [];
        const updateValues = [];
        const allowedFields = ['userName', 'userEmail', 'password', 'companyName', 'companyId', 'phoneNumber', 'bloodGroup', 'user_role', 'branch_id'];

        // Log all received fields for debugging
        console.log('Received fields:', Object.keys(updateData));
        console.log('Field values:', updateData);

        // Check each allowed field
        allowedFields.forEach(field => {
            if (updateData[field] !== undefined && updateData[field] !== null) {
                if (field === 'password' && updateData[field]) {
                    // Hash the password before storing
                    const salt = bcrypt.genSaltSync(10);
                    const hashedPassword = bcrypt.hashSync(updateData[field], salt);
                    updateFields.push('password = ?');
                    updateValues.push(hashedPassword);
                } else if (field === 'companyId') {
                    // Validate company exists when updating companyId
                    const checkCompanyQuery = "SELECT id FROM company WHERE id = ?";
                    db.query(checkCompanyQuery, [updateData[field]], (companyErr, companyResult) => {
                        if (companyErr || companyResult.length === 0) {
                            return res.status(400).json({ error: 'Invalid companyId.' });
                        }
                        updateFields.push('companyId = ?');
                        updateValues.push(updateData[field]);
                    });
                } else if (field === 'branch_id' && updateData[field]) {
                    // Validate branch exists and belongs to the company
                    const checkBranchQuery = "SELECT branch_id FROM branch WHERE branch_id = ? AND company_id = ?";
                    db.query(checkBranchQuery, [updateData[field], companyId], (branchErr, branchResult) => {
                        if (branchErr || branchResult.length === 0) {
                            return res.status(400).json({ error: 'Invalid branch_id or branch does not belong to the company.' });
                        }
                        updateFields.push('branch_id = ?');
                        updateValues.push(updateData[field]);
                    });
                } else if (updateData[field] !== '') {
                    // Only include non-empty string values for other fields
                    updateFields.push(`${field} = ?`);
                    updateValues.push(updateData[field]);
                }
            }
        });

        console.log('Fields to update:', updateFields);
        console.log('Values to update:', updateValues);

        if (updateFields.length === 0) {
            console.error('No valid fields to update');
            return res.status(400).json({ 
                error: 'No valid fields to update',
                receivedData: updateData
            });
        }

        // Add userId to values array for WHERE clause
        updateValues.push(userId);

        const updateQuery = `UPDATE profile_picture SET ${updateFields.join(', ')} WHERE userId = ?`;
        
        db.query(updateQuery, updateValues, (err, result) => {
            if (err) {
                console.error('Error updating user:', err);
                return res.status(500).json({ error: 'Failed to update user' });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'User not found' });
            }

            console.log('User updated successfully:', userId);
            res.status(200).json({ 
                message: 'User updated successfully',
                userId: userId
            });
        });
    });
});

// Delete user by ID
router.delete('/user/delete/:id', (req, res) => {
    console.log('DELETE /user/delete called with ID:', req.params.id);
    console.log('Request headers:', req.headers);
    
    const userId = req.params.id;
    const companyId = req.query.companyId; // Required for security validation

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required for user deletion.' });
    }

    if (!userId) {
        console.error('Error: User ID is required');
        return res.status(400).json({ error: 'User ID is required' });
    }

    console.log('Checking if user exists with ID:', userId, 'and companyId:', companyId);
    const checkSql = "SELECT * FROM profile_picture WHERE userId = ? AND companyId = ?";
    db.query(checkSql, [userId, companyId], (checkErr, checkResult) => {
        if (checkErr) {
            console.error('Database error when checking user:', {
                error: checkErr,
                sql: checkSql,
                userId: userId,
                companyId: companyId
            });
            return res.status(500).json({ 
                error: 'Error checking user',
                details: checkErr.message 
            });
        }

        console.log('User check result:', {
            userId: userId,
            companyId: companyId,
            userExists: checkResult.length > 0,
            userData: checkResult[0] || null
        });

        if (checkResult.length === 0) {
            console.error(`User not found with ID: ${userId} in company: ${companyId}`);
            return res.status(404).json({ 
                error: 'User not found or access denied',
                userId: userId,
                companyId: companyId
            });
        }

        console.log(`Attempting to delete user with ID: ${userId} from company: ${companyId}`);
        const deleteSql = "DELETE FROM profile_picture WHERE userId = ? AND companyId = ?";
        db.query(deleteSql, [userId, companyId], (deleteErr, deleteResult) => {
            if (deleteErr) {
                console.error('Database error when deleting user:', {
                    error: deleteErr,
                    sql: deleteSql,
                    userId: userId,
                    companyId: companyId
                });
                return res.status(500).json({ 
                    error: 'Failed to delete user',
                    details: deleteErr.message 
                });
            }

            console.log('Delete operation result:', {
                affectedRows: deleteResult.affectedRows,
                changedRows: deleteResult.changedRows,
                message: deleteResult.message
            });

            if (deleteResult.affectedRows > 0) {
                console.log(`User ${userId} deleted successfully from company ${companyId}`);
                return res.status(200).json({ 
                    success: true,
                    message: 'User deleted successfully',
                    userId: userId,
                    companyId: companyId
                });
            } else {
                console.error(`No rows affected when deleting user ${userId} from company ${companyId}`);
                return res.status(404).json({ 
                    error: 'User not found or already deleted',
                    userId: userId,
                    companyId: companyId
                });
            }
        });
    });
});

router.post('/change-password', async (req, res) => {
    const { userId, oldPassword, newPassword, companyId } = req.body;

    if (!userId || !oldPassword || !newPassword || !companyId) {
        return res.status(400).json({ error: 'User ID, old password, new password, and companyId are required.' });
    }

    // Fetch the user data including the hashed password from the database
    const sql = "SELECT * FROM profile_picture WHERE userId = ? AND companyId = ?";
    db.query(sql, [userId, companyId], async (err, data) => {
        if (err) {
            console.error('Error fetching user data:', err);
            return res.status(500).json({ error: 'An error occurred, please try again' });
        }
        if (data.length === 0) {
            return res.status(404).json({ error: 'User not found or access denied' });
        }

        // Get the stored hashed password
        const storedHashedPassword = data[0].password;

        // Compare the provided old password with the stored hashed password
        try {
            const isMatch = await bcrypt.compare(oldPassword, storedHashedPassword);
            if (isMatch) {
                // Hash the new password
                const hashedNewPassword = await bcrypt.hash(newPassword, 10);

                // Update the password in the database
                const updateSql = "UPDATE profile_picture SET password = ? WHERE userId = ? AND companyId = ?";
                db.query(updateSql, [hashedNewPassword, userId, companyId], (updateErr, updateData) => {
                    if (updateErr) {
                        console.error('Error updating password:', updateErr);
                        return res.status(500).json({ error: 'An error occurred, please try again' });
                    }
                    return res.json({ message: 'Password updated successfully' });
                });
            } else {
                return res.status(401).json({ error: 'Invalid old password' });
            }
        } catch (error) {
            console.error('Error comparing passwords:', error);
            return res.status(500).json({ error: 'An error occurred, please try again' });
        }
    });
});


// Route to check if an email already exists
router.post('/user/check-email', (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ error: 'Email is required.' });
    }

    const sql = "SELECT COUNT(*) AS count FROM profile_picture WHERE userEmail = ?";
    db.query(sql, [email], (err, result) => {
        if (err) {
            console.error('Error checking email:', err);
            return res.status(500).json({ error: 'Internal server error' });
        }

        const exists = result[0].count > 0;
        res.json({ exists });
    });
});


// Route to retrieve user data including profile picture filename
router.get('/data/:userId', (req, res) => {
    const userId = req.params.userId;
    const companyId = req.query.companyId; // Required for security validation

    if (!userId) {
        return res.status(400).json({ error: 'User ID is required.' });
    }

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required for user data access.' });
    }

    const sql = "SELECT * FROM profile_picture WHERE userId = ? AND companyId = ?";
    db.query(sql, [userId, companyId], (err, data) => {
        if (err) {
            console.error('Error fetching profile picture:', err);
            return res.status(500).json({ error: 'An error occurred. Try again later.' });
        }

        if (data.length === 0) {
            return res.status(404).json({ error: 'User not found or access denied.' });
        }

        // If user found and has a filename, add the full image URL
        if (data && data.length > 0 && data[0].filename) {
            data[0].imageUrl = `/profile-picture/${userId}`;
        }

        return res.json(data);
    });
});

// Route to serve the actual profile picture file
router.get('/profile-picture/:userId', async (req, res) => {
    const userId = req.params.userId;
    console.log(`Request received for profile picture of user ${userId}`);

    if (!userId) {
        console.error('No user ID provided');
        return res.status(400).json({ error: 'User ID is required.' });
    }

    // Ensure uploads directory exists
    const uploadsDir = path.join(__dirname, 'uploads');
    try {
        await fsPromises.access(uploadsDir);
    } catch (error) {
        console.log('Uploads directory does not exist, creating it...');
        await fsPromises.mkdir(uploadsDir, { recursive: true });
    }

    try {
        // First, get the filename from the database
        const sql = "SELECT filename FROM profile_picture WHERE userId = ?";
        const [data] = await new Promise((resolve, reject) => {
            db.query(sql, [userId], (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
        
        if (!data || !data.filename) {
            console.log(`No profile picture found in database for user ${userId}`);
            return await serveDefaultAvatar(res);
        }

        const filename = data.filename;
        const imagePath = path.join(uploadsDir, filename);
        console.log(`Attempting to serve file from path: ${imagePath}`);

        try {
            // Check if file exists
            await fsPromises.access(imagePath);
            
            // Set cache control headers
            res.setHeader('Cache-Control', 'public, max-age=86400');
            
            // Send the actual image file
            res.sendFile(imagePath, (err) => {
                if (err) {
                    console.error('Error sending profile picture:', err);
                    serveDefaultAvatar(res, 'Error serving profile picture');
                }
            });
        } catch (err) {
            console.error(`File not found at path: ${imagePath}`, err);
            await serveDefaultAvatar(res, `Profile picture file not found: ${filename}`);
        }
    } catch (err) {
        console.error('Database error when fetching profile picture:', err);
        res.status(500).json({ 
            error: 'Database error', 
            details: err.message 
        });
    }
});

// Helper function to serve default avatar
async function serveDefaultAvatar(res, errorMessage = '') {
    const defaultAvatarPath = path.join(__dirname, 'default-avatar.png');
    
    try {
        // Check if default avatar exists
        await fsPromises.access(defaultAvatarPath);
        
        // Serve the default avatar
        res.sendFile(defaultAvatarPath, (err) => {
            if (err) {
                console.error('Error sending default avatar:', err);
                sendSvgAvatar(res, errorMessage);
            }
        });
    } catch (err) {
        console.error('Default avatar not found at path:', defaultAvatarPath);
        sendSvgAvatar(res, errorMessage);
    }
}

// Helper function to send SVG avatar
function sendSvgAvatar(res, errorMessage) {
    const defaultAvatar = `
        <svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
            <rect width="100%" height="100%" fill="#f0f0f0"/>
            <circle cx="100" cy="80" r="50" fill="#ccc"/>
            <circle cx="100" cy="200" r="80" fill="#ccc"/>
            ${errorMessage ? `<text x="100" y="120" text-anchor="middle" fill="#666" font-size="12">${errorMessage}</text>` : ''}
        </svg>`;
    
    res.setHeader('Content-Type', 'image/svg+xml');
    res.status(404).send(defaultAvatar);
}

router.get('/mobile/login', async (req, res) => {
    const { userEmail, password, companyId, branchId } = req.query; // companyId is required, branchId is optional

    if (!userEmail || !password || !companyId) {
        return res.status(400).json({ error: 'User email, password, and companyId are required.' });
    }

    const sql = "SELECT * FROM profile_picture WHERE userEmail = ?";
    db.query(sql, [userEmail], async (err, data) => {
        if (err) {
            console.error('Error fetching user data:', err);
            return res.status(500).json({ error: 'An error occurred, please try again' });
        }
        if (data.length === 0) {
            return res.status(404).json({ error: 'Invalid email or password' });
        }

        const user = data[0];

        // Validate company access - user must belong to the specified company
        if (parseInt(user.companyId) !== parseInt(companyId)) {
            console.log(`Company access denied for user ${userEmail}: user belongs to company ${user.companyId}, attempting login to company ${companyId}`);
            return res.status(403).json({ error: 'Access denied. User does not belong to this company.' });
        }

        // Validate branch access if branchId is specified
        if (branchId) {
            if (user.branch_id === null) {
                console.log(`Branch access denied for user ${userEmail}: user has no branch assignment, attempting login to branch ${branchId}`);
                return res.status(403).json({ error: 'Access denied. User is not assigned to any branch.' });
            }
            if (parseInt(user.branch_id) !== parseInt(branchId)) {
                console.log(`Branch access denied for user ${userEmail}: user belongs to branch ${user.branch_id}, attempting login to branch ${branchId}`);
                return res.status(403).json({ error: 'Access denied. User does not belong to this branch.' });
            }
        }

        // Get the stored hashed password
        const storedHashedPassword = user.password;
        console.log(password);
        console.log(storedHashedPassword);
        // Compare the provided password with the stored hashed password
        try {
            const isMatch = await bcrypt.compare(password, storedHashedPassword);
            if (isMatch) {
                // Remove sensitive data before returning
                const { password: _, ...userData } = user;
                return res.json({
                    ...userData,
                    loginCompanyId: companyId,
                    loginBranchId: branchId || null
                }); // Return the user data (or other appropriate response)
            } else {
                return res.status(401).json({ error: 'Invalid email or password' });
            }
        } catch (error) {
            console.error('Error comparing passwords:', error);
            return res.status(500).json({ error: 'An error occurred, please try again' });
        }
    });
})


router.post('/user/add', upload.single('profilePicture'), async (req, res) => {
    const { userName, userEmail, password, companyName, phoneNumber, bloodGroup, companyId, user_role = 'user', branch_id } = req.body;

    // Check if all required fields are provided (companyId is now required)
    if (!userName || !userEmail || !password || !companyName || !companyId) {
        return res.status(400).json({ 
            error: 'All fields are required including companyId.', 
            received: { userName, userEmail, password: password ? '***' : null, companyName, companyId, branch_id }
        });
    }

    // Validate companyId exists
    const checkCompanyQuery = "SELECT id FROM company WHERE id = ?";
    db.query(checkCompanyQuery, [companyId], (companyErr, companyResult) => {
        if (companyErr) {
            console.error('Error checking company:', companyErr);
            return res.status(500).json({ error: 'Error validating company' });
        }

        if (companyResult.length === 0) {
            return res.status(400).json({ error: 'Invalid companyId. Company does not exist.' });
        }

        // Validate branch_id if provided
        if (branch_id) {
            const checkBranchQuery = "SELECT branch_id FROM branch WHERE branch_id = ? AND company_id = ?";
            db.query(checkBranchQuery, [branch_id, companyId], (branchErr, branchResult) => {
                if (branchErr) {
                    console.error('Error checking branch:', branchErr);
                    return res.status(500).json({ error: 'Error validating branch' });
                }

                if (branchResult.length === 0) {
                    return res.status(400).json({ 
                        error: 'Invalid branch_id. Branch does not exist or does not belong to the specified company.' 
                    });
                }

                // Proceed with user creation
                createUser();
            });
        } else {
            // No branch_id provided, proceed with user creation
            createUser();
        }

        function createUser() {
            // Check if a file was uploaded
            let filename = null;
            if (req.file) {
                filename = req.file.filename;
            }

            // Hash the password
            bcrypt.hash(password, 10).then(hashedPassword => {
                const insertQuery = "INSERT INTO profile_picture (userName, userEmail, password, companyName, phoneNumber, bloodGroup, companyId, filename, user_role, branch_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                db.query(insertQuery, [userName, userEmail, hashedPassword, companyName, phoneNumber, bloodGroup, companyId, filename, user_role, branch_id], (err, result) => {
                    if (err) {
                        console.error('Error adding user:', err);
                        if (err.code === 'ER_DUP_ENTRY') {
                            return res.status(409).json({ error: 'User with this email already exists' });
                        }
                        return res.status(500).json({ error: 'Internal server error' });
                    }

                    console.log('User added successfully:', { userEmail, companyId, branch_id });
                    res.status(201).json({ 
                        message: 'User added successfully',
                        userId: result.insertId,
                        companyId: companyId,
                        branchId: branch_id
                    });
                });
            }).catch(err => {
                console.error('Error hashing password:', err);
                res.status(500).json({ error: 'Internal server error' });
            });
        }
    });
});






module.exports = router;
