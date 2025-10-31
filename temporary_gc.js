const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const axios = require('axios');
const db = require('./db');
const { setInterval } = require('timers');

// In-memory SSE client registry per CompanyId
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
                
                const hoursSinceCreation = results[0].hours_since_creation;
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
router.post('/create', async (req, res) => {
    try {
        const { userId, companyId, branchId, ...gcData } = req.body;
        console.log('gcData', gcData);
        console.log('userId', userId);
        console.log('companyId', companyId);
        console.log('branchId', branchId);

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
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.'
                });
            }
        }

        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            return res.status(403).json({ 
                success: false, 
                message: 'Only admins can create temporary GCs' 
            });
        }

        const tempGcNumber = generateTempGCNumber();

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
                console.error('Error creating temporary GC:', err);
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to create temporary GC',
                    error: err.message 
                });
            }

            res.status(201).json({
                success: true,
                message: 'Temporary GC created successfully',
                data: {
                    id: result.insertId,
                    temp_gc_number: tempGcNumber,
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
        console.error('Error in create temporary GC:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error',
            error: error.message 
        });
    }
});

// Get all available temporary GCs
router.get('/list', (req, res) => {
    const { companyId, branchId } = req.query;

    if (!companyId) {
        return res.status(400).json({ 
            success: false, 
            message: 'Company ID is required' 
        });
    }

    let sql = `
        SELECT * FROM temporary_gc 
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
            console.error('Error fetching temporary GCs:', err);
            return res.status(500).json({ 
                success: false, 
                message: 'Failed to fetch temporary GCs',
                error: err.message 
            });
        }

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
    const { tempGcNumber } = req.params;
    const { adminUserId, companyId, branchId } = req.body;

    if (!adminUserId) {
        return res.status(400).json({
            success: false,
            message: 'Admin user ID is required'
        });
    }

    if (!companyId) {
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    try {
        const adminStatus = await isAdmin(adminUserId);
        if (!adminStatus) {
            return res.status(403).json({
                success: false,
                message: 'Only admins can force unlock temporary GCs'
            });
        }

        // Validate admin belongs to the specified company
        const adminCheck = await new Promise((resolve, reject) => {
            db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [adminUserId, companyId], (err, result) => {
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

        const companySql = 'SELECT CompanyId FROM temporary_gc WHERE temp_gc_number = ?';
        db.query(companySql, [tempGcNumber], (companyErr, rows) => {
            if (companyErr) {
                console.error('Error fetching company for force unlock:', companyErr);
                return res.status(500).json({
                    success: false,
                    message: 'Failed to force unlock temporary GC',
                    error: companyErr.message
                });
            }

            const tempGCCompanyId = rows && rows[0] ? rows[0].CompanyId : null;

            if (tempGCCompanyId !== companyId) {
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
                    console.error('Error force unlocking temporary GC:', unlockErr);
                    return res.status(500).json({
                        success: false,
                        message: 'Failed to force unlock temporary GC',
                        error: unlockErr.message
                    });
                }

                if (!result || result.affectedRows === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Temporary GC is not locked'
                    });
                }

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
        console.error('Error verifying admin for force unlock:', error);
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
        SELECT * FROM temporary_gc 
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

    try {
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
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
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
                console.error('Error checking lock status:', err);
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to check lock status',
                    error: err.message 
                });
            }

            if (results.length === 0) {
                console.log('Results' , results)
                return res.status(404).json({ 
                    success: false, 
                    message: 'Temporary GC not found or access denied' 
                });
            }

            const tempGC = results[0];

            if (tempGC.is_locked && 
                tempGC.locked_by_user_id != userId && 
                tempGC.minutes_since_lock < 10) {
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
                    console.error('Error locking temporary GC:', err);
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Failed to lock temporary GC',
                        error: err.message 
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({ 
                        success: false, 
                        message: 'Temporary GC not found or access denied' 
                    });
                }

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
        console.error('Error in lock temporary GC:', error);
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

    // Validate user belongs to the specified company
    db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (userErr, userResult) => {
        if (userErr) {
            console.error('Error validating user:', userErr);
            return res.status(500).json({
                success: false,
                message: 'Database error validating user',
                error: userErr.message
            });
        }

        if (userResult.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userResult[0].branch_id;
            if (userBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
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
                console.error('Error fetching company for unlock:', err);
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to unlock temporary GC',
                    error: err.message 
                });
            }
            const tempGCCompanyId = rows && rows[0] ? rows[0].CompanyId : null;

            if (tempGCCompanyId !== companyId) {
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
                    console.error('Error unlocking temporary GC:', err);
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Failed to unlock temporary GC',
                        error: err.message 
                    });
                }

                if (!result || result.affectedRows === 0) {
                    return res.status(409).json({
                        success: false,
                        message: 'Temporary GC is not locked by this user or already unlocked'
                    });
                }

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

// Convert temporary GC to actual GC
router.post('/convert/:tempGcNumber', async (req, res) => {
    const { tempGcNumber } = req.params;
    const { userId, actualGcNumber, companyId, branchId, ...additionalData } = req.body;

    if (!userId || !actualGcNumber) {
        return res.status(400).json({
            success: false,
            message: 'User ID and actual GC number are required'
        });
    }

    if (!companyId) {
        return res.status(400).json({
            success: false,
            message: 'companyId is required'
        });
    }

    try {
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
                message: 'Access denied. User does not belong to this company.'
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userCheck[0].branch_id;
            if (userBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.'
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.'
                });
            }
        }

        db.getTransaction((err, tx) => {
            if (err) {
                console.error('Error starting transaction:', err);
                return res.status(500).json({
                    success: false,
                    message: 'Failed to start transaction',
                    error: err.message
                });
            }

            let checkSql = `
                SELECT * FROM temporary_gc
                WHERE temp_gc_number = ?
                AND is_converted = 0
                AND locked_by_user_id = ?
                AND CompanyId = ?
            `;
            let checkParams = [tempGcNumber, userId, companyId];

            // Add branch filter if specified
            if (branchId) {
                checkSql += ' AND branch_id = ?';
                checkParams.push(branchId);
            }

            tx.query(checkSql, checkParams, (err, results) => {
                if (err) {
                    return tx.rollback(() => {
                        console.error('Error checking temporary GC:', err);
                        res.status(500).json({
                            success: false,
                            message: 'Failed to check temporary GC',
                            error: err.message
                        });
                    });
                }

                if (results.length === 0) {
                    return tx.rollback(() => {
                        res.status(404).json({
                            success: false,
                            message: 'Temporary GC not found, already converted, or not locked by you'
                        });
                    });
                }

                const tempGC = results[0];

                const checkGcSql = 'SELECT GcNumber FROM gc_creation WHERE GcNumber = ? AND CompanyId = ?';

                tx.query(checkGcSql, [actualGcNumber, tempGC.CompanyId], (err, gcResults) => {
                    if (err) {
                        return tx.rollback(() => {
                            console.error('Error checking GC number:', err);
                            res.status(500).json({
                                success: false,
                                message: 'Failed to check GC number',
                                error: err.message
                            });
                        });
                    }

                    if (gcResults.length > 0) {
                        return tx.rollback(() => {
                            res.status(409).json({
                                success: false,
                                message: 'This GC number already exists. Another user may have filled this temporary GC.'
                            });
                        });
                    }

                    const gcFields = [
                        'BranchCode', 'Branch', 'GcDate', 'TruckNumber', 'vechileNumber', 'TruckType',
                        'BrokerNameShow', 'BrokerName', 'TripId', 'PoNumber', 'TruckFrom', 'TruckTo',
                        'PaymentDetails', 'LcNo', 'DeliveryDate', 'EBillDate', 'EBillExpDate',
                        'DriverNameShow', 'DriverName', 'DriverPhoneNumber', 'Consignor',
                        'ConsignorName', 'ConsignorAddress', 'ConsignorGst', 'Consignee',
                        'ConsigneeName', 'ConsigneeAddress', 'ConsigneeGst', 'BillTo', 'BillToName', 'BillToAddress', 'BillToGst',
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
                        'ChallanBillNoDate', 'ChallanBillAmount', 'HireAmount', 'AdvanceAmount',
                        'BalanceAmount', 'FreightCharge', 'CompanyId'
                    ];

                    const insertFields = ['GcNumber', 'created_by_user_id', ...gcFields];
                    const values = [actualGcNumber, userId];

                    gcFields.forEach(field => {
                        values.push(additionalData[field] !== undefined ? additionalData[field] : tempGC[field]);
                    });

                    const placeholders = insertFields.map(() => '?').join(', ');
                    const insertSql = `INSERT INTO gc_creation (${insertFields.join(', ')}) VALUES (${placeholders})`;

                    tx.query(insertSql, values, (err, insertResult) => {
                        if (err) {
                            return tx.rollback(() => {
                                console.error('Error inserting GC:', err);
                                res.status(500).json({
                                    success: false,
                                    message: 'Failed to create GC',
                                    error: err.message
                                });
                            });
                        }

                        let updateSql = `
                            UPDATE temporary_gc
                            SET is_converted = 1,
                                converted_gc_number = ?,
                                converted_by_user_id = ?,
                                converted_at = NOW(),
                                is_locked = 0,
                                locked_by_user_id = NULL,
                                locked_at = NULL
                            WHERE temp_gc_number = ? AND CompanyId = ?
                        `;
                        let updateParams = [actualGcNumber, userId, tempGcNumber, companyId];

                        // Add branch filter if specified
                        if (branchId) {
                            updateSql += ' AND branch_id = ?';
                            updateParams.push(branchId);
                        }

                        tx.query(updateSql, updateParams, (err, updateResult) => {
                            if (err) {
                                return tx.rollback(() => {
                                    console.error('Error updating temporary GC:', err);
                                    res.status(500).json({
                                        success: false,
                                        message: 'Failed to update temporary GC status',
                                        error: err.message
                                    });
                                });
                            }

                            // First commit the transaction
                            tx.commit(async (err) => {
                                if (err) {
                                    return tx.rollback(() => {
                                        console.error('Error committing transaction:', err);
                                        res.status(500).json({
                                            success: false,
                                            message: 'Failed to commit transaction',
                                            error: err.message
                                        });
                                    });
                                }

                                try {
                                    // Call submit-gc endpoint to mark the GC number as used
                                    await axios.post('http://localhost:8080/gc-management/submit-gc', {
                                        userId: userId,
                                        companyId: parseInt(companyId, 10),
                                        branchId: branchId ? parseInt(branchId, 10) : null
                                    });

                                    console.log(`GC number ${actualGcNumber} marked as used for user ${userId}`);

                                    // Only send success response after the GC is marked as used
                                    res.json({
                                        success: true,
                                        message: 'Temporary GC converted to actual GC successfully',
                                        data: {
                                            gc_number: actualGcNumber,
                                            gc_id: insertResult.insertId,
                                            companyId: parseInt(companyId, 10),
                                            branchId: branchId ? parseInt(branchId, 10) : null
                                        }
                                    });
                                } catch (error) {
                                    console.error('Error marking GC as used:', error.message);
                                    // Even if marking as used fails, we've already committed the transaction
                                    // So we'll still send a success response but log the error
                                    res.json({
                                        success: true,
                                        message: 'Temporary GC converted to actual GC successfully, but failed to mark GC as used',
                                        warning: 'GC number was not marked as used in the system',
                                        data: {
                                            gc_number: actualGcNumber,
                                            gc_id: insertResult.insertId,
                                            companyId: parseInt(companyId, 10),
                                            branchId: branchId ? parseInt(branchId, 10) : null
                                        }
                                    });
                                }

                                // Broadcast conversion to remove from list for this company
                                broadcast(String(tempGC.CompanyId), 'temp_gc_converted', {
                                    temp_gc_number: tempGcNumber,
                                    gc_number: actualGcNumber
                                });
                            });
                        });
                    });
                });
            });
        });
    } catch (error) {
        console.error('Error in convert temporary GC:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
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

module.exports = router;
