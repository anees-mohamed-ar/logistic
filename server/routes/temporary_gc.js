const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// Note: You'll need to update this path based on your actual db.js location
// Assuming db.js is in the root of backend folder
const db = require('../../db');

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
            resolve(results.length > 0 && results[0].user_role === 'admin');
        });
    });
}

// Check if GC can be edited (24-hour restriction for non-admin)
async function canEditGC(gcNumber, companyId, userId) {
    return new Promise((resolve, reject) => {
        // First check if user is admin
        isAdmin(userId).then(adminStatus => {
            if (adminStatus) {
                // Admin can always edit
                resolve({ canEdit: true, isAdmin: true });
                return;
            }

            // For non-admin, check 24-hour restriction
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
        const { userId, ...gcData } = req.body;

        if (!userId) {
            return res.status(400).json({ 
                success: false, 
                message: 'User ID is required' 
            });
        }

        // Check if user is admin
        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            return res.status(403).json({ 
                success: false, 
                message: 'Only admins can create temporary GCs' 
            });
        }

        // Generate unique temporary GC number
        const tempGcNumber = generateTempGCNumber();

        // Prepare SQL with all fields
        const fields = [
            'temp_gc_number', 'created_by_user_id', 'BranchCode', 'Branch', 'GcDate',
            'TruckNumber', 'vechileNumber', 'TruckType', 'BrokerNameShow', 'BrokerName',
            'TripId', 'PoNumber', 'TruckFrom', 'TruckTo', 'PaymentDetails', 'LcNo',
            'DeliveryDate', 'EBillDate', 'EBillExpDate', 'DriverNameShow', 'DriverName',
            'DriverPhoneNumber', 'Consignor', 'ConsignorName', 'ConsignorAddress',
            'ConsignorGst', 'Consignee', 'ConsigneeName', 'ConsigneeAddress',
            'ConsigneeGst', 'CustInvNo', 'InvValue', 'EInv', 'EInvDate', 'Eda',
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
            'HireAmount', 'AdvanceAmount', 'BalanceAmount', 'FreightCharge', 'CompanyId'
        ];

        const placeholders = fields.map(() => '?').join(', ');
        const values = [tempGcNumber, userId];
        
        // Add all field values
        fields.slice(2).forEach(field => {
            values.push(gcData[field] || null);
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
                    temp_gc_number: tempGcNumber
                }
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

// Get all available temporary GCs (not converted, not locked or lock expired)
router.get('/list', (req, res) => {
    const { companyId } = req.query;

    if (!companyId) {
        return res.status(400).json({ 
            success: false, 
            message: 'Company ID is required' 
        });
    }

    // Get temporary GCs that are:
    // 1. Not converted
    // 2. Either not locked OR locked more than 10 minutes ago (lock expired)
    const sql = `
        SELECT * FROM temporary_gc 
        WHERE CompanyId = ? 
        AND is_converted = 0 
        AND (
            is_locked = 0 
            OR TIMESTAMPDIFF(MINUTE, locked_at, NOW()) > 10
        )
        ORDER BY created_at DESC
    `;

    db.query(sql, [companyId], (err, results) => {
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
            data: results
        });
    });
});

// Get single temporary GC by temp_gc_number
router.get('/get/:tempGcNumber', (req, res) => {
    const { tempGcNumber } = req.params;

    const sql = 'SELECT * FROM temporary_gc WHERE temp_gc_number = ?';

    db.query(sql, [tempGcNumber], (err, results) => {
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
                message: 'Temporary GC not found' 
            });
        }

        res.json({
            success: true,
            data: results[0]
        });
    });
});

// Lock temporary GC when user starts editing
router.post('/lock/:tempGcNumber', async (req, res) => {
    const { tempGcNumber } = req.params;
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).json({ 
            success: false, 
            message: 'User ID is required' 
        });
    }

    try {
        // Check if already locked by another user (within last 10 minutes)
        const checkSql = `
            SELECT is_locked, locked_by_user_id, locked_at,
                   TIMESTAMPDIFF(MINUTE, locked_at, NOW()) as minutes_since_lock
            FROM temporary_gc 
            WHERE temp_gc_number = ? AND is_converted = 0
        `;

        db.query(checkSql, [tempGcNumber], (err, results) => {
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
                    message: 'Temporary GC not found or already converted' 
                });
            }

            const tempGC = results[0];

            // Check if locked by another user and lock is still valid (< 10 minutes)
            if (tempGC.is_locked && 
                tempGC.locked_by_user_id !== userId && 
                tempGC.minutes_since_lock < 10) {
                return res.status(423).json({ 
                    success: false, 
                    message: 'This temporary GC is currently being edited by another user',
                    locked_by: tempGC.locked_by_user_id,
                    locked_at: tempGC.locked_at
                });
            }

            // Lock the temporary GC
            const lockSql = `
                UPDATE temporary_gc 
                SET is_locked = 1, locked_by_user_id = ?, locked_at = NOW() 
                WHERE temp_gc_number = ? AND is_converted = 0
            `;

            db.query(lockSql, [userId, tempGcNumber], (err, result) => {
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
                        message: 'Temporary GC not found or already converted' 
                    });
                }

                res.json({
                    success: true,
                    message: 'Temporary GC locked successfully'
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

// Unlock temporary GC (if user cancels editing)
router.post('/unlock/:tempGcNumber', (req, res) => {
    const { tempGcNumber } = req.params;
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).json({ 
            success: false, 
            message: 'User ID is required' 
        });
    }

    const sql = `
        UPDATE temporary_gc 
        SET is_locked = 0, locked_by_user_id = NULL, locked_at = NULL 
        WHERE temp_gc_number = ? AND locked_by_user_id = ?
    `;

    db.query(sql, [tempGcNumber, userId], (err, result) => {
        if (err) {
            console.error('Error unlocking temporary GC:', err);
            return res.status(500).json({ 
                success: false, 
                message: 'Failed to unlock temporary GC',
                error: err.message 
            });
        }

        res.json({
            success: true,
            message: 'Temporary GC unlocked successfully'
        });
    });
});

// Convert temporary GC to actual GC
router.post('/convert/:tempGcNumber', async (req, res) => {
    const { tempGcNumber } = req.params;
    const { userId, actualGcNumber, ...additionalData } = req.body;

    if (!userId || !actualGcNumber) {
        return res.status(400).json({ 
            success: false, 
            message: 'User ID and actual GC number are required' 
        });
    }

    try {
        // Start transaction
        db.beginTransaction((err) => {
            if (err) {
                console.error('Error starting transaction:', err);
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to start transaction',
                    error: err.message 
                });
            }

            // Check if temporary GC exists and is locked by this user
            const checkSql = `
                SELECT * FROM temporary_gc 
                WHERE temp_gc_number = ? 
                AND is_converted = 0 
                AND locked_by_user_id = ?
            `;

            db.query(checkSql, [tempGcNumber, userId], (err, results) => {
                if (err) {
                    return db.rollback(() => {
                        console.error('Error checking temporary GC:', err);
                        res.status(500).json({ 
                            success: false, 
                            message: 'Failed to check temporary GC',
                            error: err.message 
                        });
                    });
                }

                if (results.length === 0) {
                    return db.rollback(() => {
                        res.status(404).json({ 
                            success: false, 
                            message: 'Temporary GC not found, already converted, or not locked by you' 
                        });
                    });
                }

                const tempGC = results[0];

                // Check if actual GC number already exists
                const checkGcSql = 'SELECT GcNumber FROM gc_creation WHERE GcNumber = ? AND CompanyId = ?';
                
                db.query(checkGcSql, [actualGcNumber, tempGC.CompanyId], (err, gcResults) => {
                    if (err) {
                        return db.rollback(() => {
                            console.error('Error checking GC number:', err);
                            res.status(500).json({ 
                                success: false, 
                                message: 'Failed to check GC number',
                                error: err.message 
                            });
                        });
                    }

                    if (gcResults.length > 0) {
                        return db.rollback(() => {
                            res.status(409).json({ 
                                success: false, 
                                message: 'This GC number already exists. Another user may have filled this temporary GC.' 
                            });
                        });
                    }

                    // Merge temporary GC data with additional data provided by user
                    const gcFields = [
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

                    const insertFields = ['GcNumber', 'created_by_user_id', ...gcFields];
                    const values = [actualGcNumber, userId];

                    gcFields.forEach(field => {
                        // Use additional data if provided, otherwise use temp GC data
                        values.push(additionalData[field] !== undefined ? additionalData[field] : tempGC[field]);
                    });

                    const placeholders = insertFields.map(() => '?').join(', ');
                    const insertSql = `INSERT INTO gc_creation (${insertFields.join(', ')}) VALUES (${placeholders})`;

                    db.query(insertSql, values, (err, insertResult) => {
                        if (err) {
                            return db.rollback(() => {
                                console.error('Error inserting GC:', err);
                                res.status(500).json({ 
                                    success: false, 
                                    message: 'Failed to create GC',
                                    error: err.message 
                                });
                            });
                        }

                        // Mark temporary GC as converted
                        const updateSql = `
                            UPDATE temporary_gc 
                            SET is_converted = 1, 
                                converted_gc_number = ?, 
                                converted_by_user_id = ?, 
                                converted_at = NOW(),
                                is_locked = 0,
                                locked_by_user_id = NULL,
                                locked_at = NULL
                            WHERE temp_gc_number = ?
                        `;

                        db.query(updateSql, [actualGcNumber, userId, tempGcNumber], (err, updateResult) => {
                            if (err) {
                                return db.rollback(() => {
                                    console.error('Error updating temporary GC:', err);
                                    res.status(500).json({ 
                                        success: false, 
                                        message: 'Failed to update temporary GC status',
                                        error: err.message 
                                    });
                                });
                            }

                            // Commit transaction
                            db.commit((err) => {
                                if (err) {
                                    return db.rollback(() => {
                                        console.error('Error committing transaction:', err);
                                        res.status(500).json({ 
                                            success: false, 
                                            message: 'Failed to commit transaction',
                                            error: err.message 
                                        });
                                    });
                                }

                                res.json({
                                    success: true,
                                    message: 'Temporary GC converted to actual GC successfully',
                                    data: {
                                        gc_number: actualGcNumber,
                                        gc_id: insertResult.insertId
                                    }
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
        const { userId, ...updateData } = req.body;

        if (!userId) {
            return res.status(400).json({ 
                success: false, 
                message: 'User ID is required' 
            });
        }

        // Check if user is admin
        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            return res.status(403).json({ 
                success: false, 
                message: 'Only admins can update temporary GCs' 
            });
        }

        // Build update query dynamically
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

        const sql = `
            UPDATE temporary_gc 
            SET ${updates.join(', ')} 
            WHERE temp_gc_number = ? AND is_converted = 0
        `;

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
                message: 'Temporary GC updated successfully'
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

// Delete temporary GC (Admin only, only if not converted)
router.delete('/delete/:tempGcNumber', async (req, res) => {
    try {
        const { tempGcNumber } = req.params;
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({ 
                success: false, 
                message: 'User ID is required' 
            });
        }

        // Check if user is admin
        const adminStatus = await isAdmin(userId);
        if (!adminStatus) {
            return res.status(403).json({ 
                success: false, 
                message: 'Only admins can delete temporary GCs' 
            });
        }

        const sql = 'DELETE FROM temporary_gc WHERE temp_gc_number = ? AND is_converted = 0';

        db.query(sql, [tempGcNumber], (err, result) => {
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
                message: 'Temporary GC deleted successfully'
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

// Check if user can edit a GC (for 24-hour restriction bypass for admin)
router.get('/can-edit/:gcNumber', async (req, res) => {
    try {
        const { gcNumber } = req.params;
        const { companyId, userId } = req.query;

        if (!companyId || !userId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Company ID and User ID are required' 
            });
        }

        const result = await canEditGC(gcNumber, companyId, userId);
        
        res.json({
            success: true,
            ...result
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

module.exports = router;
