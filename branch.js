const express = require('express');
const router = express.Router();
const db = require('./db');

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

// Get all branches
router.get('/list', (req, res) => {
    const sql = "SELECT * FROM branch ORDER BY branch_name";
    db.query(sql, (err, data) => {
        if (err) {
            console.error('Error fetching branches:', err);
            return res.status(500).json({ error: 'Error fetching branches' });
        }
        return res.json(data);
    });
});

// Get branches for a specific company
router.get('/company/:companyId', (req, res) => {
    const { companyId } = req.params;
    const sql = "SELECT * FROM branch WHERE company_id = ? ORDER BY branch_name";
    db.query(sql, [companyId], (err, data) => {
        if (err) {
            console.error('Error fetching branches for company:', err);
            return res.status(500).json({ error: 'Error fetching branches for company' });
        }
        return res.json(data);
    });
});

// Get single branch by ID
router.get('/:id', (req, res) => {
    const { id } = req.params;
    const sql = "SELECT * FROM branch WHERE branch_id = ?";
    db.query(sql, [id], (err, data) => {
        if (err) {
            console.error('Error fetching branch:', err);
            return res.status(500).json({ error: 'Error fetching branch' });
        }
        if (data.length === 0) {
            return res.status(404).json({ error: 'Branch not found' });
        }
        return res.json(data[0]);
    });
});

// Add new branch
router.post('/add', (req, res) => {
    const { branch_name, branch_code, company_id, company_name, address, phone, email } = req.body;

    // Validate required fields
    if (!branch_name || !branch_code || !company_id || !company_name) {
        return res.status(400).json({ error: 'Branch name, code, company ID, and company name are required.' });
    }

    // Check if branch code already exists
    const checkSql = "SELECT COUNT(*) AS count FROM branch WHERE branch_code = ?";
    db.query(checkSql, [branch_code], (checkErr, checkResult) => {
        if (checkErr) {
            console.error('Error checking branch code:', checkErr);
            return res.status(500).json({ error: 'Internal server error' });
        }

        if (checkResult[0].count > 0) {
            return res.status(400).json({ error: 'Branch code already exists.' });
        }

        const insertQuery = "INSERT INTO branch (branch_name, branch_code, company_id, company_name, address, phone, email) VALUES (?, ?, ?, ?, ?, ?, ?)";
        db.query(insertQuery, [branch_name, branch_code, company_id, company_name, address, phone, email], (err, result) => {
            if (err) {
                console.error('Error adding branch:', err);
                return res.status(500).json({ error: 'Internal server error' });
            }

            console.log('Branch added successfully:', branch_name);
            res.status(201).json({ message: 'Branch added successfully', branch_id: result.insertId });
        });
    });
});

// Update branch
router.put('/update/:id', (req, res) => {
    const { id } = req.params;
    const updateData = req.body;

    console.log('Updating branch ID:', id);
    console.log('Update data:', updateData);

    // Check if branch exists
    const checkUserQuery = 'SELECT * FROM branch WHERE branch_id = ?';
    db.query(checkUserQuery, [id], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: 'Database error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Branch not found' });
        }

        // Prepare update fields and values
        const updateFields = [];
        const updateValues = [];
        const allowedFields = ['branch_name', 'branch_code', 'company_id', 'company_name', 'address', 'phone', 'email', 'status'];

        // Check each allowed field
        allowedFields.forEach(field => {
            if (updateData[field] !== undefined && updateData[field] !== null) {
                if (updateData[field] !== '') {
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

        // Add branch_id to values array for WHERE clause
        updateValues.push(id);

        const updateQuery = `UPDATE branch SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE branch_id = ?`;

        db.query(updateQuery, updateValues, (err, result) => {
            if (err) {
                console.error('Error updating branch:', err);
                return res.status(500).json({ error: 'Failed to update branch' });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'Branch not found' });
            }

            console.log('Branch updated successfully:', id);
            res.status(200).json({
                message: 'Branch updated successfully',
                branch_id: id
            });
        });
    });
});

// Delete branch
router.delete('/delete/:id', (req, res) => {
    const { id } = req.params;

    if (!id) {
        console.error('Error: Branch ID is required');
        return res.status(400).json({ error: 'Branch ID is required' });
    }

    console.log('Checking if branch exists with ID:', id);
    const checkSql = "SELECT * FROM branch WHERE branch_id = ?";
    db.query(checkSql, [id], (checkErr, checkResult) => {
        if (checkErr) {
            console.error('Database error when checking branch:', {
                error: checkErr,
                sql: checkSql,
                branch_id: id
            });
            return res.status(500).json({
                error: 'Error checking branch',
                details: checkErr.message
            });
        }

        console.log('Branch check result:', {
            branch_id: id,
            branchExists: checkResult.length > 0,
            branchData: checkResult[0] || null
        });

        if (checkResult.length === 0) {
            console.error(`Branch not found with ID: ${id}`);
            return res.status(404).json({
                error: 'Branch not found',
                branch_id: id
            });
        }

        console.log(`Attempting to delete branch with ID: ${id}`);
        const deleteSql = "DELETE FROM branch WHERE branch_id = ?";
        db.query(deleteSql, [id], (deleteErr, deleteResult) => {
            if (deleteErr) {
                console.error('Database error when deleting branch:', {
                    error: deleteErr,
                    sql: deleteSql,
                    branch_id: id
                });
                return res.status(500).json({
                    error: 'Failed to delete branch',
                    details: deleteErr.message
                });
            }

            console.log('Delete operation result:', {
                affectedRows: deleteResult.affectedRows,
                changedRows: deleteResult.changedRows,
                message: deleteResult.message
            });

            if (deleteResult.affectedRows > 0) {
                console.log(`Branch ${id} deleted successfully`);
                return res.status(200).json({
                    success: true,
                    message: 'Branch deleted successfully',
                    branch_id: id
                });
            } else {
                console.error(`No rows affected when deleting branch ${id}`);
                return res.status(404).json({
                    error: 'Branch not found or already deleted',
                    branch_id: id
                });
            }
        });
    });
});

module.exports = router;
