 const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const axios = require('axios');
const fs = require('fs');
const db = require('./db');
const { setInterval } = require('timers');
const multer = require('multer');
const path = require('path');

// Logging utility for temporary GC endpoints
const logTempGC = (level, endpoint, message, data = {}) => {
    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        level,
        service: 'temporary-gc',
        endpoint,
        message,
        ...data
    };
    
    if (level === 'error') {
        console.error(`[${timestamp}] ERROR [${endpoint}] ${message}`, data);
    } else if (level === 'warn') {
        console.warn(`[${timestamp}] WARN [${endpoint}] ${message}`, data);
    } else {
        console.log(`[${timestamp}] INFO [${endpoint}] ${message}`, data);
    }
};
const clientsByCompany = new Map(); // companyId: Set<res>

function addClient(companyId, res) {
    if (!clientsByCompany.has(companyId)) {
        clientsByCompany.set(companyId, new Set());
    }
    clientsByCompany.get(companyId).add(res);
}

function removeClient(companyId, res) {
    const set = clientsByCompany.get(companyId);
    if (!set) return;
    set.delete(res);
    if (set.size === 0) clientsByCompany.delete(companyId);
}

function sseSend(res, event, data) {
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
}

function broadcast(companyId, event, data) {
    const set = clientsByCompany.get(String(companyId));
    if (!set) return;
    for (const res of set) {
        try { sseSend(res, event, data); } catch (_) { /* ignore */ }
    }
}

// Configure multer for temporary GC file uploads
const tempGcUploadStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/gc_attachments/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'temp-gc-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const tempGcUpload = multer({
  storage: tempGcUploadStorage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit per file
  },
  fileFilter: (req, file, cb) => {
    // Accept all file types
    cb(null, true);
  }
});

// Generate unique temporary GC number
function generateTempGCNumber() {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = crypto.randomBytes(3).toString('hex').toUpperCase();
    return `TEMP-${timestamp}-${random}`;
}

// Check if user is admin
async function isAdmin(userId) {
    return new Promise((resolve, reject) => {
        const sql = 'SELECT user_role FROM profile_picture WHERE userId = ?';
        db.query(sql, [userId], (err, results) => {
            if (err) {
                reject(err);
                return;
            }
            if (results.length === 0) {
                resolve(false);
                return;
            }

            const role = results[0].user_role;
            resolve(role === 'admin' || role === 'super_admin');
        });
    });
}

// Check if GC can be edited (24-hour restriction for non-admin)
async function canEditGC(gcNumber, companyId, userId) {
    return new Promise((resolve, reject) => {
        isAdmin(userId).then(adminStatus => {
            if (adminStatus) {
                resolve({ canEdit: true, isAdmin: true });
                return;
            }

            const sql = `
                SELECT created_at, 
                       TIMESTAMPDIFF(HOUR, created_at, NOW()) as hours_since_creation
                FROM gc_creation 
                WHERE GcNumber = ? AND CompanyId = ?
            `;
            
            db.query(sql, [gcNumber, companyId], (err, results) => {
                if (err) {
                    reject(err);
                    return;
                }
                
                if (results.length === 0) {
                    resolve({ canEdit: false, message: 'GC not found' });
                    return;
                }
                
                const result = results[0];
                const hoursSinceCreation = result.hours_since_creation;
                if (hoursSinceCreation > 24) {
                    resolve({ 
                        canEdit: false, 
                        isAdmin: false,
                        message: 'Cannot edit GC after 24 hours from creation' 
                    });
                } else {
                    resolve({ canEdit: true, isAdmin: false });
                }
            });
        }).catch(reject);
    });
}

// Create temporary GC (Admin only)
router.post('/create', tempGcUpload.array('attachments', 10), async (req, res) => {
    const startTime = Date.now();
    const { userId, companyId, branchId, ...gcData } = req.body;
    
    logTempGC('info', 'POST /create', 'Create temporary GC request received', {
        userId,
        companyId,
        branchId,
        requestId: crypto.randomUUID()
    });

    try {
        if (!userId) {
            logTempGC('warn', 'POST /create', 'Missing userId in request', { userId });
            return res.status(400).json({ 
                success: false, 
                message: 'User ID is required' 
            });
        }

        if (!companyId) {
            logTempGC('warn', 'POST /create', 'Missing companyId in request', { companyId });
            return res.status(400).json({
                success: false,
                message: 'companyId is required'
            });
        }

        // Validate user belongs to the specified company
        const userCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (err, result) => {
                if (err) {
                    logTempGC('error', 'POST /create', 'Database error validating user', {
                        error: err.message,
                        userId,
                        companyId
                    });
                    reject(err);
                    return;
                }
                resolve(result);
            });
        });

        if (userCheck.length === 0) {
            logTempGC('warn', 'POST /create', 'User does not belong to company', {
                userId,
                companyId
            });
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                logTempGC('warn', 'POST /create', 'User not assigned to any branch', {
                    userId,
                    branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                logTempGC('warn', 'POST /create', 'User does not belong to branch', {
                    userId,
                    userBranchId,
                    requestedBranchId: branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.'
                });
            }
        }

        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            logTempGC('warn', 'POST /create', 'Non-admin user attempted to create temporary GC', {
                userId,
                companyId
            });
            return res.status(403).json({ 
                success: false, 
                message: 'Only admins can create temporary GCs' 
            });
        }

        const tempGcNumber = generateTempGCNumber();
        logTempGC('info', 'POST /create', 'Generated temporary GC number', {
            tempGcNumber,
            userId,
            companyId
        });

        const fields = [
            'temp_gc_number', 'created_by_user_id', 'BranchCode', 'Branch', 'GcDate',
            'TruckNumber', 'vechileNumber', 'TruckType', 'BrokerNameShow', 'BrokerName',
            'TripId', 'PoNumber', 'TruckFrom', 'TruckTo', 'PaymentDetails', 'LcNo',
            'DeliveryDate', 'EBillDate', 'EBillExpDate', 'DriverNameShow', 'DriverName',
            'DriverPhoneNumber', 'Consignor', 'ConsignorName', 'ConsignorAddress',
            'ConsignorGst', 'Consignee', 'ConsigneeName', 'ConsigneeAddress',
            'ConsigneeGst', 'BillTo', 'BillToName', 'BillToAddress', 'BillToGst',
            'CustInvNo', 'InvValue', 'EInv', 'EInvDate', 'Eda',
            'NumberofPkg', 'MethodofPkg', 'TotalRate', 'TotalWeight', 'Rate',
            'km', 'km2', 'km3', 'km4', 'ActualWeightKgs', 'Total',
            'PrivateMark', 'PrivateMark2', 'PrivateMark3', 'PrivateMark4',
            'Charges', 'Charges2', 'Charges3', 'Charges4',
            'NumberofPkg2', 'MethodofPkg2', 'Rate2', 'Total2', 'ActualWeightKgs2',
            'NumberofPkg3', 'MethodofPkg3', 'Rate3', 'Total3', 'ActualWeightKgs3',
            'NumberofPkg4', 'MethodofPkg4', 'Rate4', 'Total4', 'ActualWeightKgs4',
            'GoodContain', 'GoodContain2', 'GoodContain3', 'GoodContain4',
            'DeliveryFromSpecial', 'DeliveryAddress', 'ServiceTax',
            'ReceiptBillNo', 'ReceiptBillNoAmount', 'ReceiptBillNoDate',
            'ChallanBillNoDate', 'ChallanBillAmount',
            'HireAmount', 'AdvanceAmount', 'BalanceAmount', 'FreightCharge', 'CompanyId', 'branch_id'
        ];

        const placeholders = fields.map(() => '?').join(', ');
        const values = [tempGcNumber, userId];
        
        fields.slice(2).forEach(field => {
            values.push(gcData[field] || (field === 'CompanyId' ? companyId : (field === 'branch_id' ? branchId : null)));
        });

        const sql = `INSERT INTO temporary_gc (${fields.join(', ')}) VALUES (${placeholders})`;

        db.query(sql, values, (err, result) => {
            if (err) {
                logTempGC('error', 'POST /create', 'Failed to create temporary GC in database', {
                    error: err.message,
                    sql: sql.substring(0, 200) + '...',
                    userId,
                    companyId,
                    tempGcNumber,
                    duration: Date.now() - startTime
                });
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to create temporary GC',
                    error: err.message 
                });
            }

            logTempGC('info', 'POST /create', 'Temporary GC created successfully', {
                tempGcNumber,
                insertId: result.insertId,
                userId,
                companyId,
                branchId,
                duration: Date.now() - startTime
            });

            // Process uploaded files if any
            let attachmentFiles = [];
            if (req.files && req.files.length > 0) {
                attachmentFiles = req.files.map(file => ({
                    filename: file.filename,
                    originalName: file.originalname,
                    mimeType: file.mimetype,
                    size: file.size,
                    uploadDate: new Date().toISOString(),
                    uploadedBy: userId
                }));

                // Update the temporary GC record with attachment information
                const updateSql = 'UPDATE temporary_gc SET attachment_files = ?, attachment_count = ? WHERE Id = ? AND CompanyId = ?';
                db.query(updateSql, [JSON.stringify(attachmentFiles), attachmentFiles.length, result.insertId, companyId], (updateErr) => {
                    if (updateErr) {
                        logTempGC('error', 'POST /create', 'Failed to update temporary GC with attachments', {
                            error: updateErr.message,
                            tempGcNumber,
                            companyId,
                            attachmentCount: attachmentFiles.length
                        });
                        // Don't fail the request, just log the error
                    } else {
                        logTempGC('info', 'POST /create', 'Temporary GC updated with attachment information', {
                            tempGcNumber,
                            companyId,
                            attachmentCount: attachmentFiles.length
                        });
                    }
                });
            }

            res.status(201).json({
                success: true,
                message: 'Temporary GC created successfully',
                data: {
                    id: result.insertId,
                    temp_gc_number: tempGcNumber,
                    attachments: attachmentFiles,
                    attachmentCount: attachmentFiles.length,
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null
                }
            });

            // Broadcast creation to this company listeners
            broadcast(String(companyId), 'temp_gc_created', {
                temp_gc_number: tempGcNumber,
                id: result.insertId
            });
        });
    } catch (error) {
        logTempGC('error', 'POST /create', 'Unexpected error in create temporary GC', {
            error: error.message,
            stack: error.stack,
            userId,
            companyId,
            duration: Date.now() - startTime
        });
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error',
            error: error.message 
        });
    }
});

// Get all available temporary GCs
router.get('/list', (req, res) => {
    const startTime = Date.now();
    const { companyId, branchId } = req.query;

    logTempGC('info', 'GET /list', 'List temporary GCs request received', {
        companyId,
        branchId,
        requestId: crypto.randomUUID()
    });

    if (!companyId) {
        logTempGC('warn', 'GET /list', 'Missing companyId in request', { companyId });
        return res.status(400).json({ 
            success: false, 
            message: 'Company ID is required' 
        });
    }

    let sql = `
        SELECT *, 
               attachment_count,
               attachment_files
        FROM temporary_gc 
        WHERE CompanyId = ? 
        AND is_converted = 0
    `;
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    sql += " ORDER BY created_at DESC";

    db.query(sql, params, (err, results) => {
        if (err) {
            logTempGC('error', 'GET /list', 'Failed to fetch temporary GCs from database', {
                error: err.message,
                companyId,
                branchId,
                duration: Date.now() - startTime
            });
            return res.status(500).json({ 
                success: false, 
                message: 'Failed to fetch temporary GCs',
                error: err.message 
            });
        }

        logTempGC('info', 'GET /list', 'Temporary GCs fetched successfully', {
            companyId,
            branchId,
            resultCount: results.length,
            duration: Date.now() - startTime
        });

        res.json({
            success: true,
            data: results,
            companyId: parseInt(companyId, 10),
            branchId: branchId ? parseInt(branchId, 10) : null
        });
    });
});

// Force unlock temporary GC (Admin only)
router.post('/force-unlock/:tempGcNumber', async (req, res) => {
    const startTime = Date.now();
    const { tempGcNumber } = req.params;
    const { adminUserId, companyId, branchId } = req.body;

    logTempGC('info', 'POST /force-unlock/:tempGcNumber', 'Force unlock temporary GC request received', {
        tempGcNumber,
        adminUserId,
        companyId,
        branchId,
        requestId: crypto.randomUUID()
    });

    if (!adminUserId) {
        logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Missing adminUserId in request', { tempGcNumber });
        return res.status(400).json({
            success: false,
            message: 'Admin user ID is required'
        });
    }

    if (!companyId) {
        logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Missing companyId in request', { tempGcNumber });
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    try {
        const adminStatus = await isAdmin(adminUserId);
        if (!adminStatus) {
            logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Non-admin user attempted force unlock', {
                tempGcNumber,
                adminUserId,
                companyId
            });
            return res.status(403).json({
                success: false,
                message: 'Only admins can force unlock temporary GCs'
            });
        }

        // Validate admin belongs to the specified company
        const adminCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [adminUserId, companyId], (err, result) => {
                if (err) {
                    logTempGC('error', 'POST /force-unlock/:tempGcNumber', 'Database error validating admin', {
                        error: err.message,
                        tempGcNumber,
                        adminUserId,
                        companyId
                    });
                    reject(err);
                    return;
                }
                resolve(result);
            });
        });

        if (adminCheck.length === 0) {
            logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Admin does not belong to company', {
                tempGcNumber,
                adminUserId,
                companyId
            });
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admin does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const adminBranchId = adminCheck[0].branch_id;
            if (adminBranchId === null) {
                logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Admin not assigned to any branch', {
                    tempGcNumber,
                    adminUserId,
                    branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin is not assigned to any branch.'
                });
            }
            if (parseInt(adminBranchId) !== parseInt(branchId)) {
                logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Admin does not belong to branch', {
                    tempGcNumber,
                    adminUserId,
                    adminBranchId,
                    requestedBranchId: branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin does not belong to this branch.'
                });
            }
        }

        const companySql = 'SELECT CompanyId FROM temporary_gc WHERE temp_gc_number = ?';
        db.query(companySql, [tempGcNumber], (companyErr, rows) => {
            if (companyErr) {
                logTempGC('error', 'POST /force-unlock/:tempGcNumber', 'Failed to fetch company for temporary GC', {
                    error: companyErr.message,
                    tempGcNumber,
                    adminUserId,
                    companyId,
                    duration: Date.now() - startTime
                });
                return res.status(500).json({
                    success: false,
                    message: 'Failed to force unlock temporary GC',
                    error: companyErr.message
                });
            }

            const tempGCCompanyId = rows && rows[0] ? rows[0].CompanyId : null;

            if (tempGCCompanyId !== companyId) {
                logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Temporary GC does not belong to admin company', {
                    tempGcNumber,
                    tempGCCompanyId,
                    adminUserId,
                    companyId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Temporary GC does not belong to this company.'
                });
            }

            const sql = `
                UPDATE temporary_gc
                SET is_locked = 0,
                    locked_by_user_id = NULL,
                    locked_at = NULL
                WHERE temp_gc_number = ?
                  AND is_locked = 1
            `;

            db.query(sql, [tempGcNumber], (unlockErr, result) => {
                if (unlockErr) {
                    logTempGC('error', 'POST /force-unlock/:tempGcNumber', 'Failed to force unlock temporary GC', {
                        error: unlockErr.message,
                        tempGcNumber,
                        adminUserId,
                        companyId,
                        duration: Date.now() - startTime
                    });
                    return res.status(500).json({
                        success: false,
                        message: 'Failed to force unlock temporary GC',
                        error: unlockErr.message
                    });
                }

                if (!result || result.affectedRows === 0) {
                    logTempGC('warn', 'POST /force-unlock/:tempGcNumber', 'Temporary GC was not locked', {
                        tempGcNumber,
                        adminUserId,
                        companyId,
                        duration: Date.now() - startTime
                    });
                    return res.status(404).json({
                        success: false,
                        message: 'Temporary GC is not locked'
                    });
                }

                logTempGC('info', 'POST /force-unlock/:tempGcNumber', 'Temporary GC force unlocked successfully', {
                    tempGcNumber,
                    adminUserId,
                    companyId,
                    branchId,
                    affectedRows: result.affectedRows,
                    duration: Date.now() - startTime
                });

                res.json({
                    success: true,
                    message: 'Temporary GC force unlocked successfully',
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null
                });

                if (tempGCCompanyId) {
                    broadcast(String(tempGCCompanyId), 'temp_gc_unlocked', {
                        temp_gc_number: tempGcNumber,
                        forced: true,
                        unlockedBy: adminUserId
                    });
                }
            });
        });
    } catch (error) {
        logTempGC('error', 'POST /force-unlock/:tempGcNumber', 'Unexpected error in force unlock', {
            error: error.message,
            stack: error.stack,
            tempGcNumber,
            adminUserId,
            companyId,
            duration: Date.now() - startTime
        });
        res.status(500).json({
            success: false,
            message: 'Failed to force unlock temporary GC',
            error: error.message
        });
    }
});

// SSE stream for live updates per company
router.get('/stream', (req, res) => {
    const { companyId, branchId } = req.query;
    if (!companyId) {
        return res.status(400).json({ success: false, message: 'Company ID is required' });
    }

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders && res.flushHeaders();

    addClient(String(companyId), res);

    // Send initial list snapshot
    let sql = `
        SELECT *, 
               attachment_count,
               attachment_files
        FROM temporary_gc 
        WHERE CompanyId = ? 
        AND is_converted = 0 
        AND (
            is_locked = 0 
            OR TIMESTAMPDIFF(MINUTE, locked_at, NOW()) > 10
        )
    `;
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    sql += " ORDER BY created_at DESC";

    db.query(sql, params, (err, results) => {
        if (!err) {
            sseSend(res, 'temp_gc_snapshot', {
                items: results,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            });
        }
    });

    // Heartbeat to keep connection alive
    const hb = setInterval(() => {
        try { res.write(': ping\n\n'); } catch (_) {}
    }, 25000);

    req.on('close', () => {
        clearInterval(hb);
        removeClient(String(companyId), res);
        try { res.end(); } catch (_) {}
    });
});

// Get single temporary GC
router.get('/get/:tempGcNumber', (req, res) => {
    const { tempGcNumber } = req.params;
    const { companyId, branchId } = req.query;

    if (!companyId) {
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    let sql = 'SELECT * FROM temporary_gc WHERE temp_gc_number = ? AND CompanyId = ?';
    let params = [tempGcNumber, companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += ' AND branch_id = ?';
        params.push(branchId);
    }

    db.query(sql, params, (err, results) => {
        if (err) {
            console.error('Error fetching temporary GC:', err);
            return res.status(500).json({ 
                success: false, 
                message: 'Failed to fetch temporary GC',
                error: err.message 
            });
        }

        if (results.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Temporary GC not found or access denied',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            });
        }

        res.json({
            success: true,
            data: results[0],
            companyId: parseInt(companyId, 10),
            branchId: branchId ? parseInt(branchId, 10) : null
        });
    });
});

// Lock temporary GC
router.post('/lock/:tempGcNumber', async (req, res) => {
    const startTime = Date.now();
    const { tempGcNumber } = req.params;
    const { userId, companyId, branchId } = req.body;

    logTempGC('info', 'POST /lock/:tempGcNumber', 'Lock temporary GC request received', {
        tempGcNumber,
        userId,
        companyId,
        branchId,
        requestId: crypto.randomUUID()
    });

    if (!userId) {
        logTempGC('warn', 'POST /lock/:tempGcNumber', 'Missing userId in request', { tempGcNumber });
        return res.status(400).json({ 
            success: false, 
            message: 'User ID is required' 
        });
    }

    if (!companyId) {
        logTempGC('warn', 'POST /lock/:tempGcNumber', 'Missing companyId in request', { tempGcNumber });
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    try {
        // Validate user belongs to the specified company
        const userCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (err, result) => {
                if (err) {
                    logTempGC('error', 'POST /lock/:tempGcNumber', 'Database error validating user', {
                        error: err.message,
                        tempGcNumber,
                        userId,
                        companyId
                    });
                    reject(err);
                    return;
                }
                resolve(result);
            });
        });

        if (userCheck.length === 0) {
            logTempGC('warn', 'POST /lock/:tempGcNumber', 'User does not belong to company', {
                tempGcNumber,
                userId,
                companyId
            });
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                logTempGC('warn', 'POST /lock/:tempGcNumber', 'User not assigned to any branch', {
                    tempGcNumber,
                    userId,
                    branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                logTempGC('warn', 'POST /lock/:tempGcNumber', 'User does not belong to branch', {
                    tempGcNumber,
                    userId,
                    userBranchId,
                    requestedBranchId: branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.'
                });
            }
        }

        let checkSql = `
            SELECT CompanyId, is_locked, locked_by_user_id, locked_at,
                   TIMESTAMPDIFF(MINUTE, locked_at, NOW()) as minutes_since_lock
            FROM temporary_gc 
            WHERE temp_gc_number = ? AND is_converted = 0 AND CompanyId = ?
        `;
        let checkParams = [tempGcNumber, companyId];

        // Add branch filter if specified
        if (branchId) {
            checkSql += ' AND branch_id = ?';
            checkParams.push(branchId);
        }

        db.query(checkSql, checkParams, (err, results) => {
            if (err) {
                logTempGC('error', 'POST /lock/:tempGcNumber', 'Failed to check lock status', {
                    error: err.message,
                    tempGcNumber,
                    userId,
                    companyId,
                    duration: Date.now() - startTime
                });
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to check lock status',
                    error: err.message 
                });
            }

            if (results.length === 0) {
                logTempGC('warn', 'POST /lock/:tempGcNumber', 'Temporary GC not found or access denied', {
                    tempGcNumber,
                    userId,
                    companyId,
                    branchId
                });
                return res.status(404).json({ 
                    success: false, 
                    message: 'Temporary GC not found or access denied' 
                });
            }

            const tempGC = results[0];

            if (tempGC.is_locked && 
                tempGC.locked_by_user_id != userId && 
                tempGC.minutes_since_lock < 10) {
                logTempGC('warn', 'POST /lock/:tempGcNumber', 'Temporary GC already locked by another user', {
                    tempGcNumber,
                    userId,
                    lockedByUserId: tempGC.locked_by_user_id,
                    lockedAt: tempGC.locked_at,
                    minutesSinceLock: tempGC.minutes_since_lock
                });
                return res.status(423).json({ 
                    success: false, 
                    message: 'This temporary GC is currently being edited by another user',
                    locked_by: tempGC.locked_by_user_id,
                    locked_at: tempGC.locked_at
                });
            }

            let lockSql = `
                UPDATE temporary_gc 
                SET is_locked = 1, locked_by_user_id = ?, locked_at = NOW() 
                WHERE temp_gc_number = ? AND is_converted = 0 AND CompanyId = ?
            `;
            let lockParams = [userId, tempGcNumber, companyId];

            // Add branch filter if specified
            if (branchId) {
                lockSql += ' AND branch_id = ?';
                lockParams.push(branchId);
            }

            db.query(lockSql, lockParams, (err, result) => {
                if (err) {
                    logTempGC('error', 'POST /lock/:tempGcNumber', 'Failed to lock temporary GC', {
                        error: err.message,
                        tempGcNumber,
                        userId,
                        companyId,
                        duration: Date.now() - startTime
                    });
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Failed to lock temporary GC',
                        error: err.message 
                    });
                }

                if (result.affectedRows === 0) {
                    logTempGC('warn', 'POST /lock/:tempGcNumber', 'Failed to lock - GC not found or access denied', {
                        tempGcNumber,
                        userId,
                        companyId,
                        branchId,
                        affectedRows: result.affectedRows
                    });
                    return res.status(404).json({ 
                        success: false, 
                        message: 'Temporary GC not found or access denied' 
                    });
                }

                logTempGC('info', 'POST /lock/:tempGcNumber', 'Temporary GC locked successfully', {
                    tempGcNumber,
                    userId,
                    companyId,
                    branchId,
                    affectedRows: result.affectedRows,
                    duration: Date.now() - startTime
                });

                res.json({
                    success: true,
                    message: 'Temporary GC locked successfully',
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null
                });

                // Broadcast lock event
                broadcast(String(tempGC.CompanyId), 'temp_gc_locked', {
                    temp_gc_number: tempGcNumber,
                    locked_by_user_id: userId
                });
            });
        });
    } catch (error) {
        logTempGC('error', 'POST /lock/:tempGcNumber', 'Unexpected error in lock temporary GC', {
            error: error.message,
            stack: error.stack,
            tempGcNumber,
            userId,
            companyId,
            duration: Date.now() - startTime
        });
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error',
            error: error.message 
        });
    }
});

// Check lock status
router.get('/check-lock/:tempGcNumber', (req, res) => {
    const { tempGcNumber } = req.params;
    const { companyId, branchId } = req.query;

    if (!companyId) {
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    let sql = `
        SELECT 
            is_locked,
            locked_by_user_id,
            locked_at,
            TIMESTAMPDIFF(MINUTE, locked_at, NOW()) as minutes_locked,
            (SELECT username FROM profile_picture WHERE userId = locked_by_user_id) as locked_by_username
        FROM temporary_gc 
        WHERE temp_gc_number = ? AND CompanyId = ?
    `;
    let params = [tempGcNumber, companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += ' AND branch_id = ?';
        params.push(branchId);
    }

    db.query(sql, params, (err, results) => {
        if (err) {
            console.error('Error checking lock status:', err);
            return res.status(500).json({
                success: false,
                message: 'Failed to check lock status',
                error: err.message
            });
        }

        if (results.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Temporary GC not found or access denied',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            });
        }

        const lockInfo = results[0];

        // Check if lock exists but is expired (older than 30 minutes)
        if (lockInfo.is_locked && lockInfo.minutes_locked > 30) {
            // Auto-release the expired lock
            let updateSql = 'UPDATE temporary_gc SET is_locked = 0, locked_by_user_id = NULL, locked_at = NULL WHERE temp_gc_number = ? AND CompanyId = ?';
            let updateParams = [tempGcNumber, companyId];
            if (branchId) {
                updateSql += ' AND branch_id = ?';
                updateParams.push(branchId);
            }

            return db.query(updateSql, updateParams, (updateErr) => {
                if (updateErr) {
                    console.error('Error releasing expired lock:', updateErr);
                    return res.status(500).json({
                        success: false,
                        message: 'Failed to release expired lock',
                        error: updateErr.message
                    });
                }

                return res.json({
                    isLocked: false,
                    wasLocked: true,
                    message: 'Lock was expired and has been released',
                    lockedBy: lockInfo.locked_by_username,
                    lockedAt: lockInfo.locked_at,
                    lockedAgo: `${lockInfo.minutes_locked} minutes ago`,
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null
                });
            });
        }

        // Return current lock status
        res.json({
            isLocked: lockInfo.is_locked === 1,
            lockedByUserId: lockInfo.locked_by_user_id,
            lockedBy: lockInfo.locked_by_username,
            lockedAt: lockInfo.locked_at,
            lockedAgo: lockInfo.locked_at ? `${lockInfo.minutes_locked} minutes ago` : null,
            companyId: parseInt(companyId, 10),
            branchId: branchId ? parseInt(branchId, 10) : null
        });
    });
});

// Unlock temporary GC
router.post('/unlock/:tempGcNumber', (req, res) => {
    const startTime = Date.now();
    const { tempGcNumber } = req.params;
    const { userId, companyId, branchId } = req.body;

    logTempGC('info', 'POST /unlock/:tempGcNumber', 'Unlock temporary GC request received', {
        tempGcNumber,
        userId,
        companyId,
        branchId,
        requestId: crypto.randomUUID()
    });

    if (!userId) {
        logTempGC('warn', 'POST /unlock/:tempGcNumber', 'Missing userId in request', { tempGcNumber });
        return res.status(400).json({ 
            success: false, 
            message: 'User ID is required' 
        });
    }

    if (!companyId) {
        logTempGC('warn', 'POST /unlock/:tempGcNumber', 'Missing companyId in request', { tempGcNumber });
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    // Validate user belongs to the specified company
    db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (userErr, userResult) => {
        if (userErr) {
            logTempGC('error', 'POST /unlock/:tempGcNumber', 'Database error validating user', {
                error: userErr.message,
                tempGcNumber,
                userId,
                companyId,
                duration: Date.now() - startTime
            });
            return res.status(500).json({
                success: false,
                message: 'Database error validating user',
                error: userErr.message
            });
        }

        if (userResult.length === 0) {
            logTempGC('warn', 'POST /unlock/:tempGcNumber', 'User does not belong to company', {
                tempGcNumber,
                userId,
                companyId
            });
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userResult[0].branch_id;
            if (userBranchId === null) {
                logTempGC('warn', 'POST /unlock/:tempGcNumber', 'User not assigned to any branch', {
                    tempGcNumber,
                    userId,
                    branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                logTempGC('warn', 'POST /unlock/:tempGcNumber', 'User does not belong to branch', {
                    tempGcNumber,
                    userId,
                    userBranchId,
                    requestedBranchId: branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.'
                });
            }
        }

        // Get CompanyId for broadcasting
        const companySql = 'SELECT CompanyId FROM temporary_gc WHERE temp_gc_number = ?';
        db.query(companySql, [tempGcNumber], (err, rows) => {
            if (err) {
                logTempGC('error', 'POST /unlock/:tempGcNumber', 'Failed to fetch company for unlock', {
                    error: err.message,
                    tempGcNumber,
                    userId,
                    companyId,
                    duration: Date.now() - startTime
                });
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to unlock temporary GC',
                    error: err.message 
                });
            }
            const tempGCCompanyId = rows && rows[0] ? rows[0].CompanyId : null;

            if (tempGCCompanyId !== companyId) {
                logTempGC('warn', 'POST /unlock/:tempGcNumber', 'Temporary GC does not belong to company', {
                    tempGcNumber,
                    tempGCCompanyId,
                    userId,
                    companyId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Temporary GC does not belong to this company.'
                });
            }

            let sql = `
                UPDATE temporary_gc 
                SET is_locked = 0, locked_by_user_id = NULL, locked_at = NULL 
                WHERE temp_gc_number = ? AND locked_by_user_id = ? AND CompanyId = ?
            `;
            let params = [tempGcNumber, userId, companyId];

            // Add branch filter if specified
            if (branchId) {
                sql += ' AND branch_id = ?';
                params.push(branchId);
            }

            db.query(sql, params, (err, result) => {
                if (err) {
                    logTempGC('error', 'POST /unlock/:tempGcNumber', 'Failed to unlock temporary GC', {
                        error: err.message,
                        tempGcNumber,
                        userId,
                        companyId,
                        duration: Date.now() - startTime
                    });
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Failed to unlock temporary GC',
                        error: err.message 
                    });
                }

                if (!result || result.affectedRows === 0) {
                    logTempGC('warn', 'POST /unlock/:tempGcNumber', 'Temporary GC not locked by this user', {
                        tempGcNumber,
                        userId,
                        companyId,
                        branchId,
                        affectedRows: result.affectedRows
                    });
                    return res.status(409).json({
                        success: false,
                        message: 'Temporary GC is not locked by this user or already unlocked'
                    });
                }

                logTempGC('info', 'POST /unlock/:tempGcNumber', 'Temporary GC unlocked successfully', {
                    tempGcNumber,
                    userId,
                    companyId,
                    branchId,
                    affectedRows: result.affectedRows,
                    duration: Date.now() - startTime
                });

                res.json({
                    success: true,
                    message: 'Temporary GC unlocked successfully',
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null
                });

                if (tempGCCompanyId) {
                    broadcast(String(tempGCCompanyId), 'temp_gc_unlocked', {
                        temp_gc_number: tempGcNumber
                    });
                }
        });
    });
});
});

// Update temporary GC (Admin only)
router.put('/update/:tempGcNumber', async (req, res) => {
    try {
        const { tempGcNumber } = req.params;
        const { userId, companyId, branchId, ...updateData } = req.body;

        if (!userId) {
            return res.status(400).json({
                success: false,
                message: 'User ID is required'
            });
        }

        if (!companyId) {
            return res.status(400).json({
                success: false,
                message: 'companyId is required'
            });
        }

        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            return res.status(403).json({
                success: false,
                message: 'Only admins can update temporary GCs'
            });
        }

        // Validate admin belongs to the specified company
        const adminCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (err, result) => {
                if (err) reject(err);
                else resolve(result);
            });
        });

        if (adminCheck.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admin does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const adminBranchId = adminCheck[0].branch_id;
            if (adminBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin is not assigned to any branch.'
                });
            }
            if (parseInt(adminBranchId) !== parseInt(branchId)) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin does not belong to this branch.'
                });
            }
        }

        const allowedFields = [
            'BranchCode', 'Branch', 'GcDate', 'TruckNumber', 'vechileNumber', 'TruckType',
            'BrokerNameShow', 'BrokerName', 'TripId', 'PoNumber', 'TruckFrom', 'TruckTo',
            'PaymentDetails', 'LcNo', 'DeliveryDate', 'EBillDate', 'EBillExpDate',
            'DriverNameShow', 'DriverName', 'DriverPhoneNumber', 'Consignor',
            'ConsignorName', 'ConsignorAddress', 'ConsignorGst', 'Consignee',
            'ConsigneeName', 'ConsigneeAddress', 'ConsigneeGst', 'CustInvNo',
            'InvValue', 'EInv', 'EInvDate', 'Eda', 'NumberofPkg', 'MethodofPkg',
            'TotalRate', 'TotalWeight', 'Rate', 'km', 'km2', 'km3', 'km4',
            'ActualWeightKgs', 'Total', 'PrivateMark', 'PrivateMark2', 'PrivateMark3',
            'PrivateMark4', 'Charges', 'Charges2', 'Charges3', 'Charges4',
            'NumberofPkg2', 'MethodofPkg2', 'Rate2', 'Total2', 'ActualWeightKgs2',
            'NumberofPkg3', 'MethodofPkg3', 'Rate3', 'Total3', 'ActualWeightKgs3',
            'NumberofPkg4', 'MethodofPkg4', 'Rate4', 'Total4', 'ActualWeightKgs4',
            'GoodContain', 'GoodContain2', 'GoodContain3', 'GoodContain4',
            'DeliveryFromSpecial', 'DeliveryAddress', 'ServiceTax',
            'ReceiptBillNo', 'ReceiptBillNoAmount', 'ReceiptBillNoDate',
            'ChallanBillNoDate', 'ChallanBillAmount', 'HireAmount', 'AdvanceAmount',
            'BalanceAmount', 'FreightCharge', 'CompanyId'
        ];

        const updates = [];
        const values = [];

        allowedFields.forEach(field => {
            if (updateData[field] !== undefined) {
                updates.push(`${field} = ?`);
                values.push(updateData[field]);
            }
        });

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No valid fields to update'
            });
        }

        values.push(tempGcNumber);
        values.push(companyId); // Add company filter

        let sql = `
            UPDATE temporary_gc
            SET ${updates.join(', ')}
            WHERE temp_gc_number = ? AND is_converted = 0 AND CompanyId = ?
        `;

        // Add branch filter if specified
        if (branchId) {
            sql += ' AND branch_id = ?';
            values.push(branchId);
        }

        db.query(sql, values, (err, result) => {
            if (err) {
                console.error('Error updating temporary GC:', err);
                return res.status(500).json({
                    success: false,
                    message: 'Failed to update temporary GC',
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Temporary GC not found or already converted'
                });
            }

            res.json({
                success: true,
                message: 'Temporary GC updated successfully',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null,
                updatedRecords: result.affectedRows
            });
        });
    } catch (error) {
        console.error('Error in update temporary GC:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Delete temporary GC (Admin only)
router.delete('/delete/:tempGcNumber', async (req, res) => {
    try {
        const { tempGcNumber } = req.params;
        const { userId, companyId, branchId } = req.body;

        if (!userId) {
            return res.status(400).json({
                success: false,
                message: 'User ID is required'
            });
        }

        if (!companyId) {
            return res.status(400).json({
                success: false,
                message: 'companyId is required'
            });
        }

        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            return res.status(403).json({
                success: false,
                message: 'Only admins can delete temporary GCs'
            });
        }

        // Validate admin belongs to the specified company
        const adminCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (err, result) => {
                if (err) reject(err);
                else resolve(result);
            });
        });

        if (adminCheck.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admin does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const adminBranchId = adminCheck[0].branch_id;
            if (adminBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin is not assigned to any branch.'
                });
            }
            if (parseInt(adminBranchId) !== parseInt(branchId)) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin does not belong to this branch.'
                });
            }
        }

        // Find company to broadcast after delete
        let findSql = 'SELECT CompanyId FROM temporary_gc WHERE temp_gc_number = ? AND is_converted = 0';
        let findParams = [tempGcNumber];

        // Add company and branch filter if specified
        if (companyId) {
            findSql += ' AND CompanyId = ?';
            findParams.push(companyId);
        }
        if (branchId) {
            findSql += ' AND branch_id = ?';
            findParams.push(branchId);
        }

        db.query(findSql, findParams, (findErr, findRows) => {
            if (findErr) {
                console.error('Error finding temporary GC for delete:', findErr);
                return res.status(500).json({
                    success: false,
                    message: 'Failed to delete temporary GC',
                    error: findErr.message
                });
            }

            const tempGCCompanyId = findRows && findRows[0] ? findRows[0].CompanyId : null;

            if (tempGCCompanyId !== companyId) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Temporary GC does not belong to this company.'
                });
            }

            let sql = 'DELETE FROM temporary_gc WHERE temp_gc_number = ? AND is_converted = 0';
            let params = [tempGcNumber];

            // Add company and branch filter
            if (companyId) {
                sql += ' AND CompanyId = ?';
                params.push(companyId);
            }
            if (branchId) {
                sql += ' AND branch_id = ?';
                params.push(branchId);
            }

            db.query(sql, params, (err, result) => {
                if (err) {
                    console.error('Error deleting temporary GC:', err);
                    return res.status(500).json({
                        success: false,
                        message: 'Failed to delete temporary GC',
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Temporary GC not found or already converted'
                    });
                }

                res.json({
                    success: true,
                    message: 'Temporary GC deleted successfully',
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null,
                    deletedRecords: result.affectedRows
                });

                if (tempGCCompanyId) {
                    broadcast(String(tempGCCompanyId), 'temp_gc_deleted', {
                        temp_gc_number: tempGcNumber
                    });
                }
            });
        });
    } catch (error) {
        console.error('Error in delete temporary GC:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});



// Check if user can edit a GC
router.get('/can-edit/:gcNumber', async (req, res) => {
    try {
        const { gcNumber } = req.params;
        const { companyId, userId, branchId } = req.query;

        if (!companyId || !userId) {
            return res.status(400).json({
                success: false,
                message: 'Company ID and User ID are required'
            });
        }

        // Validate user belongs to the specified company
        const userCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (err, result) => {
                if (err) reject(err);
                else resolve(result);
            });
        });

        if (userCheck.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.',
                canEdit: false
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.',
                    canEdit: false
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.',
                    canEdit: false
                });
            }
        }

        const result = await canEditGC(gcNumber, companyId, userId);

        res.json({
            success: true,
            ...result,
            companyId: parseInt(companyId, 10),
            branchId: branchId ? parseInt(branchId, 10) : null
        });
    } catch (error) {
        console.error('Error checking edit permission:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Function to unlock expired temporary GCs (locked for more than 3 minutes)
async function unlockExpiredTemporaryGCs() {
    try {
        const unlockSql = `
            UPDATE temporary_gc 
            SET is_locked = 0, 
                locked_by_user_id = NULL, 
                locked_at = NULL 
            WHERE is_locked = 1 
            AND locked_at < DATE_SUB(NOW(), INTERVAL 15 MINUTE)
            AND is_converted = 0
        `;
        
        db.query(unlockSql, (err, result) => {
            if (err) {
                console.error('Error unlocking expired temporary GCs:', err);
                return;
            }
            
            if (result.affectedRows > 0) {
                console.log(`Unlocked ${result.affectedRows} temporary GCs that were locked for more than 3 minutes`);
                
                // Get the list of affected companies to broadcast updates
                const getAffectedCompaniesSql = `
                    SELECT DISTINCT CompanyId 
                    FROM temporary_gc 
                    WHERE is_locked = 1 
                    AND locked_at < DATE_SUB(NOW(), INTERVAL 15 MINUTE)
                    AND is_converted = 0
                `;
                
                db.query(getAffectedCompaniesSql, (err, companies) => {
                    if (err) {
                        console.error('Error getting affected companies for broadcast:', err);
                        return;
                    }
                    
                    // Broadcast unlock event to all affected companies
                    companies.forEach(company => {
                        broadcast(String(company.CompanyId), 'temp_gc_auto_unlocked', {
                            message: 'Some temporary GCs were automatically unlocked due to inactivity'
                        });
                    });
                });
            }
            else {
                console.log('No temporary GCs were unlocked');
            }
        });
    } catch (error) {
        console.error('Error in unlockExpiredTemporaryGCs:', error);
    }
}

// Set up interval to check for and unlock expired temporary GCs every minute
setInterval(unlockExpiredTemporaryGCs, 5000);

// Endpoint to manually trigger the unlock process (for testing and debugging)
router.post('/unlock-expired', (req, res) => {
    unlockExpiredTemporaryGCs();
    res.json({
        success: true,
        message: 'Unlock process for expired temporary GCs has been triggered'
    });
});

// Get attachments for a specific temporary GC
router.get('/attachments/:tempGcNumber', (req, res) => {
    const { tempGcNumber } = req.params;
    const { companyId, branchId } = req.query;

    logTempGC('info', 'GET /attachments/:tempGcNumber', 'Fetching temporary GC attachments', {
        tempGcNumber,
        companyId,
        branchId,
        requestId: crypto.randomUUID()
    });

    if (!companyId) {
        logTempGC('warn', 'GET /attachments/:tempGcNumber', 'Missing companyId in request', { tempGcNumber });
        return res.status(400).json({ 
            success: false, 
            message: 'companyId is required' 
        });
    }

    let sql = 'SELECT attachment_files, attachment_count FROM temporary_gc WHERE temp_gc_number = ? AND CompanyId = ?';
    let params = [tempGcNumber, companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += ' AND branch_id = ?';
        params.push(branchId);
    }

    db.query(sql, params, (err, results) => {
        if (err) {
            logTempGC('error', 'GET /attachments/:tempGcNumber', 'Failed to fetch temporary GC attachments', {
                error: err.message,
                tempGcNumber,
                companyId,
                branchId
            });
            return res.status(500).json({
                success: false,
                message: 'Failed to fetch temporary GC attachments',
                error: err.message
            });
        }

        if (results.length === 0) {
            logTempGC('warn', 'GET /attachments/:tempGcNumber', 'Temporary GC not found or access denied', {
                tempGcNumber,
                companyId,
                branchId
            });
            return res.status(404).json({
                success: false,
                message: 'Temporary GC not found or access denied'
            });
        }

        const tempGC = results[0];
        let attachments = [];

        if (tempGC.attachment_files) {
            try {
                attachments = JSON.parse(tempGC.attachment_files);
            } catch (parseErr) {
                logTempGC('error', 'GET /attachments/:tempGcNumber', 'Error parsing attachment files JSON', {
                    error: parseErr.message,
                    tempGcNumber,
                    companyId
                });
            }
        }

        logTempGC('info', 'GET /attachments/:tempGcNumber', 'Temporary GC attachments fetched successfully', {
            tempGcNumber,
            companyId,
            attachmentCount: attachments.length
        });

        res.json({
            success: true,
            data: {
                tempGcNumber,
                attachments,
                attachmentCount: tempGC.attachment_count || 0,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });
    });
});

// Serve uploaded files (shared with regular GC files since they use the same directory)
router.get('/files/:filename', (req, res) => {
    const { filename } = req.params;
    const filePath = path.join(__dirname, 'uploads/gc_attachments', filename);

    logTempGC('info', 'GET /files/:filename', 'Serving temporary GC attachment file', {
        filename,
        filePath,
        requestId: crypto.randomUUID()
    });

    // Check if file exists
    if (fs.existsSync(filePath)) {
        logTempGC('info', 'GET /files/:filename', 'File found and served', { filename });
        res.sendFile(filePath);
    } else {
        logTempGC('warn', 'GET /files/:filename', 'File not found', { filename, filePath });
        res.status(404).json({
            success: false,
            message: 'File not found'
        });
    }
});

// Custom middleware to handle both multipart and JSON requests
const handleConvertRequest = (req, res, next) => {
    if (req.headers['content-type'] && req.headers['content-type'].includes('multipart/form-data')) {
        // Use multer for multipart requests
        tempGcUpload.array('attachments', 10)(req, res, (err) => {
            if (err) {
                logTempGC('error', 'Convert Middleware', 'Multer error processing multipart data', {
                    error: err.message,
                    contentType: req.headers['content-type']
                });
                return res.status(400).json({
                    success: false,
                    message: 'File upload error',
                    error: err.message
                });
            }
            next();
        });
    } else {
        // For JSON requests, skip multer
        next();
    }
};

// Convert temporary GC to actual GC with file uploads
router.post('/convert/:tempGcNumber', handleConvertRequest, async (req, res) => {
    const startTime = Date.now();
    const { tempGcNumber } = req.params;

    // Data is available in req.body regardless of content type (handled by middleware)
    const rawData = req.body;

    logTempGC('info', 'POST /convert/:tempGcNumber', 'Convert temporary GC to actual GC request received', {
        tempGcNumber,
        actualGcNumber: rawData.actualGcNumber,
        userId: rawData.userId,
        companyId: rawData.companyId,
        branchId: rawData.branchId,
        hasFiles: !!(req.files && req.files.length > 0),
        requestId: crypto.randomUUID()
    });

    // Validate required fields
    if (!rawData.actualGcNumber || !rawData.userId || !rawData.companyId) {
        logTempGC('warn', 'POST /convert/:tempGcNumber', 'Missing required fields', {
            tempGcNumber,
            hasActualGcNumber: !!rawData.actualGcNumber,
            hasUserId: !!rawData.userId,
            hasCompanyId: !!rawData.companyId
        });
        return res.status(400).json({
            success: false,
            message: 'actualGcNumber, userId, and companyId are required'
        });
    }

    // Declare variables at function scope
    let actualGcNumber, userId, companyId, branchId, Branch, BranchCode, GcDate, TruckNumber, vechileNumber, TruckType,
        BrokerNameShow, BrokerName, TripId, PoNumber, TruckFrom, TruckTo, PaymentDetails, LcNo, DeliveryDate,
        EBillDate, EBillExpDate, DriverNameShow, DriverName, DriverPhoneNumber, Consignor, ConsignorName,
        ConsignorAddress, ConsignorGst, Consignee, ConsigneeName, ConsigneeAddress, ConsigneeGst, BillTo,
        BillToName, BillToAddress, BillToGst, CustInvNo, InvValue, EInv, EInvDate, Eda, NumberofPkg,
        MethodofPkg, ActualWeightKgs, NumberofPkg2, MethodofPkg2, ActualWeightKgs2, km, km2, km3, km4,
        NumberofPkg3, MethodofPkg3, ActualWeightKgs3, NumberofPkg4, MethodofPkg4, ActualWeightKgs4,
        PrivateMark, PrivateMark2, PrivateMark3, PrivateMark4, Charges, Charges2, Charges3, Charges4,
        GoodContain, GoodContain2, GoodContain3, GoodContain4, Rate, Total, Rate2, Total2, Rate3, Total3,
        Rate4, Total4, DeliveryFromSpecial, DeliveryAddress, ServiceTax, ReceiptBillNo, ReceiptBillNoAmount,
        ReceiptBillNoDate, TotalRate, TotalWeight, HireAmount, AdvanceAmount, BalanceAmount, FreightCharge,
        ChallanBillNoDate, ChallanBillAmount;

    try {
        // First, fetch the temporary GC data to get all existing fields
        let fetchTempGCSql = `
            SELECT * FROM temporary_gc 
            WHERE temp_gc_number = ? AND CompanyId = ? AND is_converted = 0
        `;
        const fetchParams = [tempGcNumber, rawData.companyId];

        if (rawData.branchId) {
            fetchTempGCSql += ' AND branch_id = ?';
            fetchParams.push(rawData.branchId);
        }

        const tempGCData = await new Promise((resolve, reject) => {
            db.query(fetchTempGCSql, fetchParams, (err, results) => {
                if (err) {
                    logTempGC('error', 'POST /convert/:tempGcNumber', 'Failed to fetch temporary GC data', {
                        error: err.message,
                        tempGcNumber,
                        userId: rawData.userId,
                        companyId: rawData.companyId
                    });
                    reject(err);
                    return;
                }
                resolve(results[0]);
            });
        });

        // Validate user belongs to the specified company
        const userCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [rawData.userId, rawData.companyId], (err, result) => {
                if (err) {
                    logTempGC('error', 'POST /convert/:tempGcNumber', 'Database error validating user', {
                        error: err.message,
                        tempGcNumber,
                        userId: rawData.userId,
                        companyId: rawData.companyId
                    });
                    reject(err);
                    return;
                }
                resolve(result);
            });
        });

        if (userCheck.length === 0) {
            logTempGC('warn', 'POST /convert/:tempGcNumber', 'User does not belong to company', {
                tempGcNumber,
                userId: rawData.userId,
                companyId: rawData.companyId
            });
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (rawData.branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                logTempGC('warn', 'POST /convert/:tempGcNumber', 'User not assigned to any branch', {
                    tempGcNumber,
                    userId: rawData.userId,
                    branchId: rawData.branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(rawData.branchId)) {
                logTempGC('warn', 'POST /convert/:tempGcNumber', 'User does not belong to branch', {
                    tempGcNumber,
                    userId: rawData.userId,
                    userBranchId,
                    requestedBranchId: rawData.branchId
                });
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.'
                });
            }
        }

        // Merge temporary GC data with form data (form data takes precedence)
        const mergedData = {
            ...tempGCData,
            ...rawData
        };

        // Create complete data object with defaults for any missing fields
        const data = {
            actualGcNumber: mergedData.actualGcNumber,
            userId: mergedData.userId,
            companyId: mergedData.companyId,
            branchId: mergedData.branchId,
            Branch: mergedData.Branch || mergedData.branch || '',
            BranchCode: mergedData.BranchCode || mergedData.branchCode || '',
            GcDate: mergedData.GcDate || mergedData.gcDate || '',
            TruckNumber: mergedData.TruckNumber || mergedData.truckNumber || '',
            vechileNumber: mergedData.vechileNumber || mergedData.TruckNumber || mergedData.truckNumber || '',
            TruckType: mergedData.TruckType || mergedData.truckType || '',
            BrokerNameShow: mergedData.BrokerNameShow || mergedData.brokerNameShow || '',
            BrokerName: mergedData.BrokerName || mergedData.brokerName || '',
            TripId: mergedData.TripId || mergedData.tripId || '',
            PoNumber: mergedData.PoNumber || mergedData.poNumber || '',
            TruckFrom: mergedData.TruckFrom || mergedData.truckFrom || '',
            TruckTo: mergedData.TruckTo || mergedData.truckTo || '',
            PaymentDetails: mergedData.PaymentDetails || mergedData.paymentDetails || '',
            LcNo: mergedData.LcNo || mergedData.lcNo || '',
            DeliveryDate: mergedData.DeliveryDate || mergedData.deliveryDate || '',
            EBillDate: mergedData.EBillDate || mergedData.eBillDate || '',
            EBillExpDate: mergedData.EBillExpDate || mergedData.eBillExpDate || '',
            DriverNameShow: mergedData.DriverNameShow || mergedData.driverNameShow || '',
            DriverName: mergedData.DriverName || mergedData.driverName || '',
            DriverPhoneNumber: mergedData.DriverPhoneNumber || mergedData.driverPhoneNumber || '',
            Consignor: mergedData.Consignor || mergedData.consignor || '',
            ConsignorName: mergedData.ConsignorName || mergedData.consignorName || '',
            ConsignorAddress: mergedData.ConsignorAddress || mergedData.consignorAddress || '',
            ConsignorGst: mergedData.ConsignorGst || mergedData.consignorGst || '',
            Consignee: mergedData.Consignee || mergedData.consignee || '',
            ConsigneeName: mergedData.ConsigneeName || mergedData.consigneeName || '',
            ConsigneeAddress: mergedData.ConsigneeAddress || mergedData.consigneeAddress || '',
            ConsigneeGst: mergedData.ConsigneeGst || mergedData.consigneeGst || '',
            BillTo: mergedData.BillTo || mergedData.billTo || '',
            BillToName: mergedData.BillToName || mergedData.billToName || '',
            BillToAddress: mergedData.BillToAddress || mergedData.billToAddress || '',
            BillToGst: mergedData.BillToGst || mergedData.billToGst || '',
            CustInvNo: mergedData.CustInvNo || mergedData.custInvNo || '',
            InvValue: mergedData.InvValue || mergedData.invValue || '',
            EInv: mergedData.EInv || mergedData.eInv || '',
            EInvDate: mergedData.EInvDate || mergedData.eInvDate || '',
            Eda: mergedData.Eda || mergedData.eda || '',
            NumberofPkg: mergedData.NumberofPkg || mergedData.numberofPkg || '',
            MethodofPkg: mergedData.MethodofPkg || mergedData.methodofPkg || '',
            ActualWeightKgs: mergedData.ActualWeightKgs || mergedData.actualWeightKgs || '',
            NumberofPkg2: mergedData.NumberofPkg2 || mergedData.numberofPkg2 || '',
            MethodofPkg2: mergedData.MethodofPkg2 || mergedData.methodofPkg2 || '',
            ActualWeightKgs2: mergedData.ActualWeightKgs2 || mergedData.actualWeightKgs2 || '',
            km: mergedData.km || '',
            km2: mergedData.km2 || '',
            km3: mergedData.km3 || '',
            km4: mergedData.km4 || '',
            NumberofPkg3: mergedData.NumberofPkg3 || mergedData.numberofPkg3 || '',
            MethodofPkg3: mergedData.MethodofPkg3 || mergedData.methodofPkg3 || '',
            ActualWeightKgs3: mergedData.ActualWeightKgs3 || mergedData.actualWeightKgs3 || '',
            NumberofPkg4: mergedData.NumberofPkg4 || mergedData.numberofPkg4 || '',
            MethodofPkg4: mergedData.MethodofPkg4 || mergedData.methodofPkg4 || '',
            ActualWeightKgs4: mergedData.ActualWeightKgs4 || mergedData.actualWeightKgs4 || '',
            PrivateMark: mergedData.PrivateMark || mergedData.privateMark || '',
            PrivateMark2: mergedData.PrivateMark2 || mergedData.privateMark2 || '',
            PrivateMark3: mergedData.PrivateMark3 || mergedData.privateMark3 || '',
            PrivateMark4: mergedData.PrivateMark4 || mergedData.privateMark4 || '',
            Charges: mergedData.Charges || mergedData.charges || '',
            Charges2: mergedData.Charges2 || mergedData.charges2 || '',
            Charges3: mergedData.Charges3 || mergedData.charges3 || '',
            Charges4: mergedData.Charges4 || mergedData.charges4 || '',
            GoodContain: mergedData.GoodContain || mergedData.goodContain || '',
            GoodContain2: mergedData.GoodContain2 || mergedData.goodContain2 || '',
            GoodContain3: mergedData.GoodContain3 || mergedData.goodContain3 || '',
            GoodContain4: mergedData.GoodContain4 || mergedData.goodContain4 || '',
            Rate: mergedData.Rate || mergedData.rate || '',
            Total: mergedData.Total || mergedData.total || '',
            Rate2: mergedData.Rate2 || mergedData.rate2 || '',
            Total2: mergedData.Total2 || mergedData.total2 || '',
            Rate3: mergedData.Rate3 || mergedData.rate3 || '',
            Total3: mergedData.Total3 || mergedData.total3 || '',
            Rate4: mergedData.Rate4 || mergedData.rate4 || '',
            Total4: mergedData.Total4 || mergedData.total4 || '',
            DeliveryFromSpecial: mergedData.DeliveryFromSpecial || mergedData.deliveryFromSpecial || '',
            DeliveryAddress: mergedData.DeliveryAddress || mergedData.deliveryAddress || '',
            ServiceTax: mergedData.ServiceTax || mergedData.serviceTax || '',
            ReceiptBillNo: mergedData.ReceiptBillNo || mergedData.receiptBillNo || '',
            ReceiptBillNoAmount: mergedData.ReceiptBillNoAmount || mergedData.receiptBillNoAmount || '',
            ReceiptBillNoDate: mergedData.ReceiptBillNoDate || mergedData.receiptBillNoDate || '',
            TotalRate: mergedData.TotalRate || mergedData.totalRate || '',
            TotalWeight: mergedData.TotalWeight || mergedData.totalWeight || '',
            HireAmount: mergedData.HireAmount || mergedData.hireAmount || '',
            AdvanceAmount: mergedData.AdvanceAmount || mergedData.advanceAmount || '',
            BalanceAmount: mergedData.BalanceAmount || mergedData.balanceAmount || '',
            FreightCharge: mergedData.FreightCharge || mergedData.freightCharge || '',
            ChallanBillNoDate: mergedData.ChallanBillNoDate || mergedData.challanBillNoDate || '',
            ChallanBillAmount: mergedData.ChallanBillAmount || mergedData.challanBillAmount || ''
        };

        // Extract variables from the complete data object
        actualGcNumber = data.actualGcNumber;
        userId = data.userId;
        companyId = data.companyId;
        branchId = data.branchId;
        Branch = data.Branch;
        BranchCode = data.BranchCode;
        GcDate = data.GcDate;
        TruckNumber = data.TruckNumber;
        vechileNumber = data.vechileNumber;
        TruckType = data.TruckType;
        BrokerNameShow = data.BrokerNameShow;
        BrokerName = data.BrokerName;
        TripId = data.TripId;
        PoNumber = data.PoNumber;
        TruckFrom = data.TruckFrom;
        TruckTo = data.TruckTo;
        PaymentDetails = data.PaymentDetails;
        LcNo = data.LcNo;
        DeliveryDate = data.DeliveryDate;
        EBillDate = data.EBillDate;
        EBillExpDate = data.EBillExpDate;
        DriverNameShow = data.DriverNameShow;
        DriverName = data.DriverName;
        DriverPhoneNumber = data.DriverPhoneNumber;
        Consignor = data.Consignor;
        ConsignorName = data.ConsignorName;
        ConsignorAddress = data.ConsignorAddress;
        ConsignorGst = data.ConsignorGst;
        Consignee = data.Consignee;
        ConsigneeName = data.ConsigneeName;
        ConsigneeAddress = data.ConsigneeAddress;
        ConsigneeGst = data.ConsigneeGst;
        BillTo = data.BillTo;
        BillToName = data.BillToName;
        BillToAddress = data.BillToAddress;
        BillToGst = data.BillToGst;
        CustInvNo = data.CustInvNo;
        InvValue = data.InvValue;
        EInv = data.EInv;
        EInvDate = data.EInvDate;
        Eda = data.Eda;
        NumberofPkg = data.NumberofPkg;
        MethodofPkg = data.MethodofPkg;
        ActualWeightKgs = data.ActualWeightKgs;
        NumberofPkg2 = data.NumberofPkg2;
        MethodofPkg2 = data.MethodofPkg2;
        ActualWeightKgs2 = data.ActualWeightKgs2;
        km = data.km;
        km2 = data.km2;
        km3 = data.km3;
        km4 = data.km4;
        NumberofPkg3 = data.NumberofPkg3;
        MethodofPkg3 = data.MethodofPkg3;
        ActualWeightKgs3 = data.ActualWeightKgs3;
        NumberofPkg4 = data.NumberofPkg4;
        MethodofPkg4 = data.MethodofPkg4;
        ActualWeightKgs4 = data.ActualWeightKgs4;
        PrivateMark = data.PrivateMark;
        PrivateMark2 = data.PrivateMark2;
        PrivateMark3 = data.PrivateMark3;
        PrivateMark4 = data.PrivateMark4;
        Charges = data.Charges;
        Charges2 = data.Charges2;
        Charges3 = data.Charges3;
        Charges4 = data.Charges4;
        GoodContain = data.GoodContain;
        GoodContain2 = data.GoodContain2;
        GoodContain3 = data.GoodContain3;
        GoodContain4 = data.GoodContain4;
        Rate = data.Rate;
        Total = data.Total;
        Rate2 = data.Rate2;
        Total2 = data.Total2;
        Rate3 = data.Rate3;
        Total3 = data.Total3;
        Rate4 = data.Rate4;
        Total4 = data.Total4;
        DeliveryFromSpecial = data.DeliveryFromSpecial;
        DeliveryAddress = data.DeliveryAddress;
        ServiceTax = data.ServiceTax;
        ReceiptBillNo = data.ReceiptBillNo;
        ReceiptBillNoAmount = data.ReceiptBillNoAmount;
        ReceiptBillNoDate = data.ReceiptBillNoDate;
        TotalRate = data.TotalRate;
        TotalWeight = data.TotalWeight;
        HireAmount = data.HireAmount;
        AdvanceAmount = data.AdvanceAmount;
        BalanceAmount = data.BalanceAmount;
        FreightCharge = data.FreightCharge;
        ChallanBillNoDate = data.ChallanBillNoDate;
        ChallanBillAmount = data.ChallanBillAmount;

        db.getTransaction((err, tx) => {
            if (err) {
                logTempGC('error', 'POST /convert/:tempGcNumber', 'Failed to start database transaction', {
                    error: err.message,
                    tempGcNumber,
                    userId,
                    companyId,
                    duration: Date.now() - startTime
                });
                return res.status(500).json({
                    success: false,
                    message: 'Failed to start transaction',
                    error: err.message
                });
            }

            logTempGC('info', 'POST /convert/:tempGcNumber', 'Database transaction started', {
                tempGcNumber,
                userId,
                companyId
            });

            let checkSql = `
                SELECT id, is_locked, locked_by_user_id, attachment_files, attachment_count, CompanyId
                FROM temporary_gc
                WHERE temp_gc_number = ?
                AND is_converted = 0
                AND CompanyId = ?
            `;
            let checkParams = [tempGcNumber, companyId];

            // Add branch filter if specified
            if (branchId) {
                checkSql += ' AND branch_id = ?';
                checkParams.push(branchId);
            }

            tx.query(checkSql, checkParams, (err, results) => {
                if (err) {
                    logTempGC('error', 'POST /convert/:tempGcNumber', 'Failed to check temporary GC status', {
                        error: err.message,
                        tempGcNumber,
                        userId,
                        companyId,
                        duration: Date.now() - startTime
                    });
                    return tx.rollback(() => {
                        res.status(500).json({
                            success: false,
                            message: 'Failed to check temporary GC',
                            error: err.message
                        });
                    });
                }

                if (results.length === 0) {
                    logTempGC('warn', 'POST /convert/:tempGcNumber', 'Temporary GC not found or access denied', {
                        tempGcNumber,
                        userId,
                        companyId,
                        branchId
                    });
                    return tx.rollback(() => {
                        res.status(404).json({
                            success: false,
                            message: 'Temporary GC not found or access denied'
                        });
                    });
                }

                const tempGC = results[0];

                // Check if GC is locked by this user
                if (!tempGC.is_locked || tempGC.locked_by_user_id != userId) {
                    logTempGC('warn', 'POST /convert/:tempGcNumber', 'Temporary GC not locked by this user', {
                        tempGcNumber,
                        userId,
                        isLocked: tempGC.is_locked,
                        lockedBy: tempGC.locked_by_user_id
                    });
                    return tx.rollback(() => {
                        res.status(423).json({
                            success: false,
                            message: 'Temporary GC is not locked by this user'
                        });
                    });
                }

                const checkGcSql = 'SELECT GcNumber FROM gc_creation WHERE GcNumber = ? AND CompanyId = ?';

                tx.query(checkGcSql, [actualGcNumber, tempGC.CompanyId], (err, gcResults) => {
                    if (err) {
                        logTempGC('error', 'POST /convert/:tempGcNumber', 'Failed to check if GC number already exists', {
                            error: err.message,
                            tempGcNumber,
                            actualGcNumber,
                            companyId: tempGC.CompanyId
                        });
                        return tx.rollback(() => {
                            res.status(500).json({
                                success: false,
                                message: 'Failed to check GC number',
                                error: err.message
                            });
                        });
                    }

                    if (gcResults.length > 0) {
                        logTempGC('warn', 'POST /convert/:tempGcNumber', 'GC number already exists', {
                            tempGcNumber,
                            actualGcNumber,
                            companyId: tempGC.CompanyId
                        });
                        return tx.rollback(() => {
                            res.status(409).json({
                                success: false,
                                message: 'This GC number already exists'
                            });
                        });
                    }

                    // Process attachments
                    let attachmentFiles = [];
                    let existingAttachments = [];

                    // Parse existing attachments from temporary GC
                    if (tempGC.attachment_files) {
                        try {
                            existingAttachments = JSON.parse(tempGC.attachment_files);
                        } catch (parseErr) {
                            logTempGC('error', 'POST /convert/:tempGcNumber', 'Error parsing existing attachments', {
                                error: parseErr.message,
                                tempGcNumber
                            });
                        }
                    }

                    // Add new attachments from upload
                    if (req.files && req.files.length > 0) {
                        const newAttachments = req.files.map(file => ({
                            filename: file.filename,
                            originalName: file.originalname,
                            mimeType: file.mimetype,
                            size: file.size,
                            uploadDate: new Date().toISOString(),
                            uploadedBy: userId
                        }));
                        attachmentFiles = [...existingAttachments, ...newAttachments];
                    } else {
                        attachmentFiles = existingAttachments;
                    }

                    // Create the actual GC record with only the fields that are provided
                    const gcInsertSql = `
                        INSERT INTO gc_creation (
                            GcNumber, Branch, BranchCode, GcDate, TruckNumber, vechileNumber, TruckType,
                            BrokerNameShow, BrokerName, TruckFrom, TruckTo, PaymentDetails,
                            LcNo, DeliveryDate, EBillDate, EBillExpDate, DriverNameShow, DriverName, DriverPhoneNumber,
                            Consignor, ConsignorName, ConsignorAddress, ConsignorGst,
                            Consignee, ConsigneeName, ConsigneeAddress, ConsigneeGst,
                            BillTo, BillToName, BillToAddress, BillToGst,
                            CustInvNo, InvValue, EInv, EInvDate, Eda, NumberofPkg, MethodofPkg, ActualWeightKgs,
                            TotalRate, TotalWeight, Rate, Total,
                            km, km2, km3, km4,
                            PrivateMark, PrivateMark2, PrivateMark3, PrivateMark4,
                            Charges, Charges2, Charges3, Charges4,
                            NumberofPkg2, MethodofPkg2, Rate2, Total2, ActualWeightKgs2,
                            NumberofPkg3, MethodofPkg3, Rate3, Total3, ActualWeightKgs3,
                            NumberofPkg4, MethodofPkg4, Rate4, Total4, ActualWeightKgs4,
                            GoodContain, GoodContain2, GoodContain3, GoodContain4,
                            PoNumber, TripId, DeliveryFromSpecial, DeliveryAddress, ServiceTax,
                            ReceiptBillNo, ReceiptBillNoAmount, ReceiptBillNoDate,
                            ChallanBillNoDate, ChallanBillAmount,
                            HireAmount, AdvanceAmount, BalanceAmount, FreightCharge,
                            CompanyId, branch_id, created_by_user_id,
                            attachment_files, attachment_count
                        ) VALUES (
                            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
                        )
                    `;

                    const gcValues = [
                        actualGcNumber, Branch, BranchCode, GcDate, TruckNumber, vechileNumber, TruckType,
                        BrokerNameShow, BrokerName, TruckFrom, TruckTo, PaymentDetails,
                        '', DeliveryDate, EBillDate, EBillExpDate, DriverNameShow, DriverName, DriverPhoneNumber,
                        Consignor, ConsignorName, ConsignorAddress, ConsignorGst,
                        Consignee, ConsigneeName, ConsigneeAddress, ConsigneeGst,
                        BillTo, BillToName, BillToAddress, BillToGst,
                        CustInvNo, InvValue, EInv, EInvDate, Eda, NumberofPkg, MethodofPkg, ActualWeightKgs,
                        TotalRate, TotalWeight, Rate, Total,
                        km, '', '', '', // km2, km3, km4
                        PrivateMark, '', '', '', // PrivateMark2, PrivateMark3, PrivateMark4
                        Charges, '', '', '', // Charges2, Charges3, Charges4
                        '', '', '', '', '', // NumberofPkg2, MethodofPkg2, Rate2, Total2, ActualWeightKgs2
                        '', '', '', '', '', // NumberofPkg3, MethodofPkg3, Rate3, Total3, ActualWeightKgs3
                        '', '', '', '', '', // NumberofPkg4, MethodofPkg4, Rate4, Total4, ActualWeightKgs4
                        GoodContain, '', '', '', // GoodContain2, GoodContain3, GoodContain4
                        PoNumber, TripId, DeliveryFromSpecial, DeliveryAddress, ServiceTax,
                        '', '', '', // ReceiptBillNo, ReceiptBillNoAmount, ReceiptBillNoDate
                        '', '', // ChallanBillNoDate, ChallanBillAmount
                        HireAmount, AdvanceAmount, BalanceAmount, FreightCharge,
                        companyId, branchId || null, userId,
                        JSON.stringify(attachmentFiles), attachmentFiles.length
                    ];

                    tx.query(gcInsertSql, gcValues, (gcInsertErr, gcResult) => {
                        if (gcInsertErr) {
                            logTempGC('error', 'POST /convert/:tempGcNumber', 'Error creating GC record', {
                                error: gcInsertErr.message,
                                tempGcNumber,
                                actualGcNumber,
                                companyId,
                                duration: Date.now() - startTime
                            });
                            return tx.rollback(() => {
                                res.status(500).json({
                                    success: false,
                                    message: 'Failed to create GC record',
                                    error: gcInsertErr.message
                                });
                            });
                        }

                        // Mark temporary GC as converted
                        const updateTempGC = `
                            UPDATE temporary_gc
                            SET is_converted = 1,
                                converted_gc_number = ?,
                                converted_by_user_id = ?,
                                converted_at = NOW()
                            WHERE temp_gc_number = ? AND CompanyId = ?
                        `;

                        tx.query(updateTempGC, [actualGcNumber, userId, tempGcNumber, companyId], (updateErr, updateResult) => {
                            if (updateErr) {
                                logTempGC('error', 'POST /convert/:tempGcNumber', 'Error updating temporary GC status', {
                                    error: updateErr.message,
                                    tempGcNumber,
                                    actualGcNumber,
                                    companyId
                                });
                                return tx.rollback(() => {
                                    res.status(500).json({
                                        success: false,
                                        message: 'Failed to update temporary GC status',
                                        error: updateErr.message
                                    });
                                });
                            }

                            logTempGC('info', 'POST /convert/:tempGcNumber', 'Temporary GC converted to actual GC successfully', {
                                tempGcNumber,
                                actualGcNumber,
                                companyId,
                                attachmentCount: attachmentFiles.length,
                                duration: Date.now() - startTime
                            });

                            // First commit the transaction
                            tx.commit(async (err) => {
                                if (err) {
                                    logTempGC('error', 'POST /convert/:tempGcNumber', 'Failed to commit transaction', {
                                        error: err.message,
                                        tempGcNumber,
                                        actualGcNumber,
                                        userId,
                                        companyId,
                                        duration: Date.now() - startTime
                                    });
                                    return tx.rollback(() => {
                                        res.status(500).json({
                                            success: false,
                                            message: 'Failed to commit transaction',
                                            error: err.message
                                        });
                                    });
                                }

                                logTempGC('info', 'POST /convert/:tempGcNumber', 'Database transaction committed successfully', {
                                    tempGcNumber,
                                    actualGcNumber,
                                    userId,
                                    companyId,
                                    duration: Date.now() - startTime
                                });

                                try {
                                    // Call submit-gc endpoint to mark the GC number as used
                                    await axios.post('http://localhost:8080/gc-management/submit-gc', {
                                        userId: userId,
                                        companyId: parseInt(companyId, 10),
                                        branchId: branchId ? parseInt(branchId, 10) : null
                                    });

                                    logTempGC('info', 'POST /convert/:tempGcNumber', 'GC number marked as used', {
                                        actualGcNumber,
                                        userId,
                                        companyId
                                    });

                                    // Broadcast the conversion
                                    broadcast(String(tempGC.CompanyId), 'temp_gc_converted', {
                                        temp_gc_number: tempGcNumber,
                                        converted_to: actualGcNumber,
                                        converted_by: userId,
                                        attachment_count: attachmentFiles.length
                                    });

                                    res.json({
                                        success: true,
                                        message: 'Temporary GC converted to actual GC successfully',
                                        data: {
                                            tempGcNumber,
                                            actualGcNumber,
                                            companyId,
                                            attachments: attachmentFiles,
                                            attachmentCount: attachmentFiles.length
                                        }
                                    });

                                } catch (error) {
                                    logTempGC('error', 'POST /convert/:tempGcNumber', 'Error after transaction commit', {
                                        error: error.message,
                                        stack: error.stack,
                                        tempGcNumber,
                                        actualGcNumber,
                                        userId,
                                        companyId,
                                        duration: Date.now() - startTime
                                    });
                                    // The transaction is already committed, so we can't rollback
                                    // But we should still log the error and potentially notify the user
                                }
                            });
                        });
                    });
                });
            });
        });
    } catch (error) {
        logTempGC('error', 'POST /convert/:tempGcNumber', 'Unexpected error in convert temporary GC', {
            error: error.message,
            stack: error.stack,
            tempGcNumber,
            userId,
            companyId,
            duration: Date.now() - startTime
        });
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

module.exports = router;
