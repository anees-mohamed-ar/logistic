const express = require('express');
const router = express.Router();
const GCManager = require('../gcManager');
const db = require('../db');

/**
 * @swagger
 * tags:
 *   name: GC Management
 *   description: Gift Certificate (GC) number management
 */

/**
 * @swagger
 * /api/gc-management/ranges:
 *   post:
 *     summary: Add a new GC range for a user (Admin only)
 *     tags: [GC Management]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - fromGC
 *               - count
 *               - companyId
 *             properties:
 *               userId:
 *                 type: integer
 *               fromGC:
 *                 type: string
 *                 description: The starting GC number (must be numeric, e.g., '120100')
 *                 example: "120100"
 *               count:
 *                 type: integer
 *                 description: Number of GCs in this range
 *                 example: 100
 *               companyId:
 *                 type: integer
 *                 description: The company ID this range belongs to
 *                 example: 6
 *               branchId:
 *                 type: integer
 *                 description: The branch ID this range belongs to (optional)
 *                 example: 1
 *               status:
 *                 type: string
 *                 enum: [active, queued, expired]
 *                 default: queued
 *     responses:
 *       200:
 *         description: GC range added successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/GCRange'
 */
router.post('/ranges', async (req, res) => {
    const startTime = new Date();
    const requestId = `GC_ADD_${Date.now()}`;
    
    console.log(`[${new Date().toISOString()}] [${requestId}] Starting GC range addition`, {
        userId: req.body.userId,
        fromGC: req.body.fromGC,
        count: req.body.count,
        status: req.body.status || 'queued',
        ip: req.ip,
        userAgent: req.get('user-agent')
    });
    
    try {
        const { userId, fromGC, count, status = 'queued', companyId, branchId } = req.body;
        
        if (!userId || !fromGC || !count || !companyId) {
            const errorMsg = 'Missing required fields';
            console.error(`[${new Date().toISOString()}] [${requestId}] ${errorMsg}`, {
                received: { userId, fromGC, count, companyId, branchId, status },
                required: ['userId', 'fromGC', 'count', 'companyId']
            });
            
            return res.status(400).json({ 
                success: false, 
                message: errorMsg,
                requestId
            });
        }
        
        console.log(`[${new Date().toISOString()}] [${requestId}] Adding GC range:`, {
            userId,
            fromGC,
            count,
            companyId,
            branchId,
            status
        });
        
        const result = await GCManager.addGCRange(userId, fromGC, count, status, companyId, branchId);
        
        const endTime = new Date();
        const duration = endTime - startTime;
        
        console.log(`[${endTime.toISOString()}] [${requestId}] Successfully added GC range`, {
            rangeId: result.id,
            fromGC: result.fromGC,
            toGC: result.toGC,
            status: result.status,
            duration: `${duration}ms`
        });
        
        res.json({
            success: true,
            message: 'GC range added successfully',
            requestId,
            data: result,
            meta: {
                duration: `${duration}ms`,
                timestamp: endTime.toISOString()
            }
        });
    } catch (error) {
        const errorTime = new Date();
        const duration = errorTime - startTime;
        
        console.error(`[${errorTime.toISOString()}] [${requestId}] Error adding GC range:`, {
            error: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
            duration: `${duration}ms`,
            requestBody: req.body
        });
        
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to add GC range',
            requestId,
            error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            meta: {
                duration: `${duration}ms`,
                timestamp: errorTime.toISOString()
            }
        });
    }
});

/**
 * @swagger
 * /api/gc-management/next-gc-number:
 *   get:
 *     summary: Get the next available GC number for the authenticated user
 *     tags: [GC Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Next available GC number
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     nextGC:
 *                       type: string
 *                       example: "CH00042"
 */
router.get('/next-gc-number', async (req, res) => {
    try {
        const userId = req.query.userId || (req.user ? req.user.userId : null);
        const companyId = req.query.companyId;
        const branchId = req.query.branchId; // Optional

        if (!userId || !companyId) {
            return res.status(400).json({
                success: false,
                message: 'User ID and companyId are required. Provide them as query parameters: /next-gc-number?userId=34&companyId=6'
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

        console.log("Getting next GC number for userId:", userId, "companyId:", companyId);

        const nextGC = await GCManager.getNextGCNumber(userId);

        return res.json({
            success: true,
            data: {
                nextGC,
                userId: parseInt(userId, 10),
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });
    } catch (error) {
        console.error('Error getting next GC number:', error);

        // Handle specific error cases
        const userId = req.query.userId || (req.user ? req.user.userId : null);

        if (error.message.includes('No active GC range found')) {
            return res.status(404).json({
                success: false,
                message: error.message,
                userId: userId
            });
        }

        res.status(500).json({
            success: false,
            message: error.message || 'Failed to get next GC number',
            userId: userId
        });
    }
});

// Get GC usage statistics
router.get('/gc-usage', async (req, res) => {
    try {
        // Get userId from query parameter or from authenticated user
        const userId = req.query.userId || req.user?.id;
        const companyId = req.query.companyId;
        const branchId = req.query.branchId; // Optional

        if (!userId || !companyId) {
            return res.status(400).json({
                success: false,
                message: 'User ID and companyId are required. Please provide userId and companyId as query parameters.'
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

        console.log("Fetching GC usage for userId:", userId, "companyId:", companyId);
        const usage = await GCManager.getGCUsage(userId);

        if (!usage) {
            return res.status(404).json({
                success: false,
                message: 'No active GC range found for this user',
                userId: userId,
                companyId: companyId
            });
        }

        console.log("GC Usage found:", usage);
        return res.json({
            success: true,
            data: {
                ...usage,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });
    } catch (error) {
        console.error('Error getting GC usage:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get GC usage'
        });
    }
});

// Mark a GC number as used when submitting a GC
router.post('/submit-gc', async (req, res) => {
    try {
        const { userId, companyId, branchId } = req.body; // branchId is optional

        if (!userId || !companyId) {
            return res.status(400).json({
                success: false,
                message: 'User ID and companyId are required in the request body.'
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

        console.log(`Submitting GC for user ${userId}, company ${companyId}`);

        // This will get the next GC number and mark it as used
        const usedGCNumber = await GCManager.useGCNumber(userId);

        // Here you would typically save the GC details to your GC table
        // For example:
        // await saveGCToDatabase({
        //     gcNumber: usedGCNumber,
        //     userId: userId,
        //     // ... other GC details
        // });

        res.json({
            success: true,
            message: 'GC submitted successfully',
            data: {
                gcNumber: usedGCNumber,
                userId: userId,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });

    } catch (error) {
        console.error('Error submitting GC:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to submit GC',
            error: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
});

/**
 * @swagger
 * /api/gc-management/usage:
 *   get:
 *     summary: Get GC usage statistics for the authenticated user
 *     tags: [GC Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: GC usage statistics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/GCUsage'
 */
router.get('/usage/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const companyId = req.query.companyId;
        const branchId = req.query.branchId; // Optional

        if (!userId || !companyId) {
            return res.status(400).json({
                success: false,
                message: 'User ID and companyId are required'
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

        const usage = await GCManager.getGCUsage(userId);
        res.json({
            success: true,
            data: {
                ...usage,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });
    } catch (error) {
        console.error('Error getting GC usage:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get GC usage',
            error: error.message
        });
    }
});

/**
 * @swagger
 * /api/gc-management/assignments:
 *   get:
 *     summary: Get all GC assignments with optional filtering (Admin only)
 *     tags: [GC Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: branch_code
 *         schema:
 *           type: string
 *         description: Filter by branch code
 *       - in: query
 *         name: company_id
 *         schema:
 *           type: integer
 *         description: Filter by company ID
 *       - in: query
 *         name: branch_id
 *         schema:
 *           type: integer
 *         description: Filter by branch ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, queued, expired]
 *         description: Filter by status
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of items per page
 *     responses:
 *       200:
 *         description: List of GC assignments
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/GCAssignment'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 */
router.get('/assignments', async (req, res) => {
    let connection;
    try {
        const { branch_code, status, company_id, branch_id, page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;
        
        // Get a connection from the pool
        connection = await new Promise((resolve, reject) => {
            db.getConnection((err, conn) => {
                if (err) return reject(err);
                resolve(conn);
            });
        });

        // Build the base query and count query
        let query = 'SELECT * FROM gc_count_log';
        let countQuery = 'SELECT COUNT(*) as total FROM gc_count_log';
        const whereClauses = [];
        const queryParams = [];
        
        if (branch_code) {
            whereClauses.push('branch_code = ?');
            queryParams.push(branch_code);
        }
        
        if (company_id) {
            whereClauses.push('company_id = ?');
            queryParams.push(company_id);
        }
        
        if (branch_id) {
            whereClauses.push('branch_id = ?');
            queryParams.push(branch_id);
        }
        
        if (status) {
            whereClauses.push('status = ?');
            queryParams.push(status);
        }
        
        // Add WHERE clause if there are any conditions
        if (whereClauses.length > 0) {
            const whereClause = ' WHERE ' + whereClauses.join(' AND ');
            query += whereClause;
            countQuery += whereClause;
        }
        
        // Add pagination to the main query
        query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
        const paginationParams = [...queryParams, parseInt(limit), parseInt(offset)];
        
        // Execute queries using the connection
        const [assignments] = await connection.promise().query(query, paginationParams);
        const [[{ total }]] = await connection.promise().query(countQuery, queryParams);
        
        res.json({
            success: true,
            data: assignments,
            pagination: {
                total: total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('Error fetching GC assignments:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch GC assignments',
            error: error.message
        });
    } finally {
        // Always release the connection back to the pool
        if (connection) connection.release();
    }
});

/**
 * @swagger
 * components:
 *   schemas:
 *     GCUsage:
 *       type: object
 *       properties:
 *         userName:
 *           type: string
 *         branchCode:
 *           type: string
 *         fromGC:
 *           type: string
 *         toGC:
 *           type: string
 *         currentGC:
 *           type: string
 *         totalGCs:
 *           type: integer
 *         usedGCs:
 *           type: integer
 *         remainingGCs:
 *           type: integer
 *         percentageUsed:
 *           type: number
 *         status:
 *           type: string
 *         assignedAt:
 *           type: string
 *           format: date-time
 *     GCRange:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         userId:
 *           type: integer
 *         branchCode:
 *           type: string
 *         fromGC:
 *           type: string
 *         toGC:
 *           type: string
 *         status:
 *           type: string
 *           enum: [active, queued, expired]
 *         createdAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     GCUsage:
 *       type: object
 *       properties:
 *         userName:
 *           type: string
 *         branchCode:
 *           type: string
 *         fromGC:
 *           type: string
 *         toGC:
 *           type: string
 *         currentGC:
 *           type: string
 *         totalGCs:
 *           type: integer
 *         usedGCs:
 *           type: integer
 *         remainingGCs:
 *           type: integer
 *         percentageUsed:
 *           type: number
 *         status:
 *           type: string
 *         assignedAt:
 *           type: string
 *           format: date-time
 *     GCRange:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         userId:
 *           type: integer
 *         branchCode:
 *           type: string
 *         fromGC:
 *           type: string
 *         toGC:
 *           type: string
 *         status:
 *           type: string
 *           enum: [active, queued, expired]
 *         createdAt:
 *           type: string
 *           format: date-time
 *     GCAssignment:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         userId:
 *           type: integer
 *         userName:
 *           type: string
 *         branchCode:
 *           type: string
 *         fromGC:
 *           type: string
 *         toGC:
 *           type: string
 *         currentGC:
 *           type: string
 *         status:
 *           type: string
 *           enum: [active, queued, expired]
 *         assignedAt:
 *           type: string
 *           format: date-time
 *         usedCount:
 *           type: integer
 *         totalCount:
 *           type: integer
 */

/**
 * @swagger
 * /api/gc-management/assign-range:
 *   post:
 *     summary: Assign a GC range to a user who doesn't have any ranges
 *     tags: [GC Management]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - fromGC
 *               - count
 *             properties:
 *               userId:
 *                 type: integer
 *               fromGC:
 *                 type: string
 *                 description: The starting GC number (must be numeric, e.g., '120100')
 *                 example: "120100"
 *               count:
 *                 type: integer
 *                 description: Number of GCs in this range
 *                 example: 100
 *     responses:
 *       200:
 *         description: GC range assigned successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/GCRange'
 */
router.post('/assign-range', async (req, res) => {
    try {
        const { userId, fromGC, count, companyId, branchId } = req.body; // companyId required, branchId optional

        if (!userId || !fromGC || !count || !companyId) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: userId, fromGC, count, and companyId are required'
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

        console.log(`Assigning GC range for user ${userId}, company ${companyId}`);

        const result = await GCManager.assignGCRange(userId, fromGC, count);

        res.json({
            success: true,
            message: 'GC range assigned successfully',
            data: {
                ...result,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });
    } catch (error) {
        console.error('Error assigning GC range:', error);

        if (error.message.includes('already has GC ranges assigned')) {
            return res.status(400).json({
                success: false,
                message: error.message
            });
        }

        res.status(500).json({
            success: false,
            message: error.message || 'Failed to assign GC range'
        });
    }
});

/**
 * @swagger
 * /api/gc-management/check-active-ranges/{userId}:
 *   get:
 *     summary: Check if a user has any active GC ranges
 *     tags: [GC Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The user ID to check
 *     responses:
 *       200:
 *         description: Successfully checked user's active GC ranges
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 hasActiveRanges:
 *                   type: boolean
 *                   description: True if user has active GC ranges, false otherwise
 *                 message:
 *                   type: string
 */
router.get('/check-active-ranges/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const companyId = req.query.companyId;
        const branchId = req.query.branchId; // Optional

        if (!userId || !companyId) {
            return res.status(400).json({
                success: false,
                message: 'User ID and companyId are required'
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

        const hasActiveRanges = await GCManager.hasActiveGCRanges(userId);
        console.log(hasActiveRanges);
        res.json({
            success: true,
            hasActiveRanges,
            message: hasActiveRanges
                ? 'User has active GC ranges'
                : 'User has no active GC ranges',
            userId: parseInt(userId, 10),
            companyId: parseInt(companyId, 10),
            branchId: branchId ? parseInt(branchId, 10) : null
        });
    } catch (error) {
        console.error('Error checking active GC ranges:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to check active GC ranges'
        });
    }
});

module.exports = router;