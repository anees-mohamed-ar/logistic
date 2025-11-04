const express = require('express')
const db = require('./db')
const router = express.Router();
const bodyParser = require('body-parser');
const axios = require('axios');
const config = require('./config');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for GC file uploads
const gcUploadStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/gc_attachments/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'gc-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const gcUpload = multer({
  storage: gcUploadStorage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit per file
  },
  fileFilter: (req, file, cb) => {
    // Accept all file types
    cb(null, true);
  }
});

router.get('/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT * FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});
router.get('/idonly', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT GcNumber,CompanyId FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});

router.get('/report/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT ReportDate,CompanyId FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});
router.get('/billed/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT LcNo , ReceiptBillNo, CompanyId FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});
router.get('/gcList/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT GcNumber,CompanyId FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});
router.get('/unloading/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT UnLoadedDate,CompanyId FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});
router.get('/receipt/search', (req, res) => {
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional branch filter

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = "SELECT NewReceiptDate,CompanyId FROM gc_creation WHERE CompanyId = ?";
    let params = [companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += " AND branch_id = ?";
        params.push(branchId);
    }

    db.query(sql, params, (err, data) => {
        if (err) return res.json(err);
        return res.json(data);
    });
});

router.get('/search/:id', (req, res) => {
    const id = req.params.id;
    const companyId = req.query.companyId;

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    const sql = "SELECT * FROM gc_creation WHERE Id = ? AND CompanyId = ?";
    db.query(sql, [id, companyId], (err, data) => {
        if (err) return res.json(err);
        if (data.length === 0) {
            return res.status(404).json({ error: 'GC not found or access denied' });
        }
        return res.json(data);
    });
});

router.get('/attachments/:gcNumber', (req, res) => {
    const { gcNumber } = req.params;
    const { companyId, branchId } = req.query;

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    let sql = 'SELECT attachment_files, attachment_count FROM gc_creation WHERE GcNumber = ? AND CompanyId = ?';
    let params = [gcNumber, companyId];

    // Add branch filter if specified
    if (branchId) {
        sql += ' AND branch_id = ?';
        params.push(branchId);
    }

    db.query(sql, params, (err, results) => {
        if (err) {
            console.error('Error fetching GC attachments:', err);
            return res.status(500).json({
                success: false,
                message: 'Failed to fetch GC attachments',
                error: err.message
            });
        }

        if (results.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'GC not found or access denied'
            });
        }

        const gc = results[0];
        let attachments = [];

        if (gc.attachment_files) {
            try {
                attachments = JSON.parse(gc.attachment_files);
            } catch (parseErr) {
                console.error('Error parsing attachment files JSON:', parseErr);
            }
        }

        res.json({
            success: true,
            data: {
                gcNumber,
                attachments,
                attachmentCount: gc.attachment_count || 0,
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            }
        });
    });
});

// Serve uploaded files
router.get('/files/:filename', (req, res) => {
    const { filename } = req.params;
    const filePath = path.join(__dirname, 'uploads/gc_attachments', filename);

    // Check if file exists
    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).json({
            success: false,
            message: 'File not found'
        });
    }
});


function formatDate(dateStr) {
    const date = new Date(dateStr);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0'); // Months are zero-based
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}${month}${day}`;
}


router.put('/update/:id/:gc', async (req, res) => { 
    const id = req.params.id;
    const gc = req.params.gc;
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional

    console.log("id",id);

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    // Validate that the GC belongs to the specified company
    const gcCheck = await new Promise((resolve, reject) => {
        db.query('SELECT branch_id FROM gc_creation WHERE Id = ? AND CompanyId = ?', [id, companyId], (err, result) => {
            if (err) reject(err);
            else resolve(result);
        });
    });

    if (gcCheck.length === 0) {
        return res.status(403).json({ error: 'Access denied. GC not found or does not belong to this company.' });
    }

    // Validate branch access if specified
    if (branchId) {
        const gcBranchId = gcCheck[0].branch_id;
        if (gcBranchId === null) {
            return res.status(403).json({ error: 'Access denied. GC is not assigned to any branch.' });
        }
        if (parseInt(gcBranchId) !== parseInt(branchId)) {
            return res.status(403).json({ error: 'Access denied. GC does not belong to this branch.' });
        }
    }

    const {Day1,Day1Place,
        Day2, Day2Place, Day3, Day3Place, Day4, Day4Place, Day5, Day5Place, Day6, Day6Place,
        Day7, Day7Place, Day8, Day8Place, ReceiptRemarks, ReportRemarks, ReportDate,
        UnloadedDate, NewReceiptDate, UnloadedRemark, Success
    } = req.body;
console.log("req",req.body);
    const ReportTime = ReportRemarks ? new Date() : null;
    const ReceiptTime = ReceiptRemarks ? new Date() : null;
    const UnloadedTime = UnloadedRemark ? new Date() : null;

    const sql = `
        UPDATE gc_creation 
        SET Day1=?,Day1Place=?,
            Day2= ?, Day2Place= ?, Day3= ?, Day3Place= ?, Day4= ?, Day4Place= ?,
            Day5= ?, Day5Place= ?, Day6= ?, Day6Place= ?, Day7= ?, Day7Place= ?,
            Day8= ?, Day8Place= ?, ReceiptRemarks= ?, ReportRemarks= ?, ReportDate= ?,
            UnloadedDate= ?, NewReceiptDate= ?, UnloadedRemark= ?, ReceiptTime = ?,
            UnloadedTime = ?, ReportTime = ?, Success= ?
        WHERE Id = ? AND CompanyId = ?`;

    const values = [Day1,Day1Place,
        Day2, Day2Place, Day3, Day3Place, Day4, Day4Place, Day5, Day5Place, Day6, Day6Place,
        Day7, Day7Place, Day8, Day8Place, ReceiptRemarks, ReportRemarks, ReportDate,
        UnloadedDate, NewReceiptDate, UnloadedRemark, ReceiptTime, UnloadedTime, ReportTime,
        Success, id, companyId
    ];
 console.log("SQL Query:", sql);
    console.log("values",values);
    

    db.query(sql, values, async (err, result) => {
        if (err) {
            console.error("Database error:", err);
            return res.status(500).json({ error: "Internal server error" });
            
        }
           console.log("DB Query Result:", result); // IMPORTANT: Log the result object
        console.log("Affected Rows:", result ? result.affectedRows : 'No result object'); // Check affected rows
           if (result && result.affectedRows === 0) {
            console.warn(`No rows updated for ID: ${id}. Check if the ID exists or if values are unchanged.`);
            // You might want to send a different status code or message here
            // return res.status(404).json({ message: "No record found or no changes made for the given ID." });
        }

    
        console.log(gc);
        

        const tallyRequestXML = `
            <ENVELOPE>
                <HEADER>
                    <TALLYREQUEST>Import Data</TALLYREQUEST>
                </HEADER>
                <BODY>
                    <IMPORTDATA>
                        <REQUESTDESC>
                            <REPORTNAME>All Masters</REPORTNAME>
                            <STATICVARIABLES>
                                <SVCURRENTCOMPANY>Globe Transport Corporation HO</SVCURRENTCOMPANY>
                            </STATICVARIABLES>
                        </REQUESTDESC>
                        <REQUESTDATA>
                            <TALLYMESSAGE xmlns:UDF="TallyUDF">
                                <STOCKITEM NAME="${gc}" RESERVEDNAME="">
                                    <ACTION>Alter</ACTION>
                                    <NAME.LIST>
                                        <NAME>${gc}</NAME>
                                    </NAME.LIST>
                                
                                  
                                    <UDF:SKDELDY1DT.LIST DESC="'SkDelDy1Dt'" ISLIST="YES" TYPE="Date" INDEX="5564">
                                    <UDF:SKDELDY1DT DESC="'SkDelDy1Dt'">${formatDate(Day1)}</UDF:SKDELDY1DT>
                                    </UDF:SKDELDY1DT.LIST>
                                    <UDF:SKDELDY2DT.LIST DESC="'SkDelDy2Dt'" ISLIST="YES" TYPE="Date" INDEX="5564">
                                    <UDF:SKDELDY2DT DESC="'SkDelDy2Dt'">${formatDate(Day2)}</UDF:SKDELDY2DT>
                                    </UDF:SKDELDY2DT.LIST>
                                    <UDF:SKDELDY3DT.LIST DESC="'SkDelDy3Dt'" ISLIST="YES" TYPE="Date" INDEX="5566">
                                    <UDF:SKDELDY3DT DESC="'SkDelDy3Dt'">${formatDate(Day3)}</UDF:SKDELDY3DT>
                                    </UDF:SKDELDY3DT.LIST>
                                    <UDF:SKDELDY4DT.LIST DESC="'SkDelDy4Dt'" ISLIST="YES" TYPE="Date" INDEX="5568">
                                    <UDF:SKDELDY4DT DESC="'SkDelDy4Dt'">${formatDate(Day4)}</UDF:SKDELDY4DT>
                                    </UDF:SKDELDY4DT.LIST>
                                    <UDF:SKDELDY5DT.LIST DESC="'SkDelDy5Dt'" ISLIST="YES" TYPE="Date" INDEX="5570">
                                    <UDF:SKDELDY5DT DESC="'SkDelDy5Dt'">${formatDate(Day5)}</UDF:SKDELDY5DT>
                                    </UDF:SKDELDY5DT.LIST>
                                    <UDF:SKDELDY6DT.LIST DESC="'SkDelDy6Dt'" ISLIST="YES" TYPE="Date" INDEX="5572">
                                    <UDF:SKDELDY6DT DESC="'SkDelDy6Dt'">${formatDate(Day6)}</UDF:SKDELDY6DT>
                                    </UDF:SKDELDY6DT.LIST>
                                    <UDF:SKDELDY7DT.LIST DESC="'SkDelDy7Dt'" ISLIST="YES" TYPE="Date" INDEX="5574">
                                    <UDF:SKDELDY7DT DESC="'SkDelDy7Dt'">${formatDate(Day7)}</UDF:SKDELDY7DT>
                                    </UDF:SKDELDY7DT.LIST>
                                    <UDF:SKDELDY8DT.LIST DESC="'SkDelDy8Dt'" ISLIST="YES" TYPE="Date" INDEX="5581">
                                    <UDF:SKDELDY8DT DESC="'SkDelDy8Dt'">${formatDate(Day8)}</UDF:SKDELDY8DT>
                                    </UDF:SKDELDY8DT.LIST>
                              
                                     <UDF:SKDELDY2LOC.LIST DESC="'SkDelDy2Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY2LOC DESC="'SkDelDy2Loc'">${Day2Place}</UDF:SKDELDY2LOC>
      </UDF:SKDELDY2LOC.LIST>
      <UDF:SKDELDY3LOC.LIST DESC="'SkDelDyLoc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY3LOC DESC="'SkDelDy3Loc'">${Day3Place}</UDF:SKDELDY3LOC>
      </UDF:SKDELDY3LOC.LIST>
       <UDF:SKDELDY4LOC.LIST DESC="'SkDelDy4Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY4LOC DESC="'SkDelDy4Loc'">${Day4Place}</UDF:SKDELDY4LOC>
      </UDF:SKDELDY4LOC.LIST>

       <UDF:SKDELDY5LOC.LIST DESC="'SkDelDy5Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY5LOC DESC="'SkDelDy5Loc'">${Day5Place}</UDF:SKDELDY5LOC>
      </UDF:SKDELDY5LOC.LIST>

       <UDF:SKDELDY6LOC.LIST DESC="'SkDelDy6Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY6LOC DESC="'SkDelDy6Loc'">${Day6Place}</UDF:SKDELDY6LOC>
      </UDF:SKDELDY6LOC.LIST>

       <UDF:SKDELDY7LOC.LIST DESC="'SkDelDy7Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY7LOC DESC="'SkDelDy7Loc'">${Day7Place}</UDF:SKDELDY7LOC>
      </UDF:SKDELDY7LOC.LIST>

       <UDF:SKDELDY8LOC.LIST DESC="'SkDelDy8Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY8LOC DESC="'SkDelDy8Loc'">${Day8Place}</UDF:SKDELDY8LOC>
      </UDF:SKDELDY8LOC.LIST>

       <UDF:MAMULAMT.LIST DESC="'MamulAmt'" ISLIST="YES" TYPE="Amount" INDEX="5585">
       <UDF:MAMULAMT DESC="'MamulAmt'">0</UDF:MAMULAMT>
      </UDF:MAMULAMT.LIST>

       <UDF:SKRPTDT.LIST DESC="'SkRptDt'" ISLIST="YES" TYPE="Date" INDEX="5560">
       <UDF:SKRPTDT DESC="'SkRptDt'">${ReportDate ? formatDate(ReportDate) : ''}</UDF:SKRPTDT>
      </UDF:SKRPTDT.LIST>
        <UDF:SKUNLOADDT.LIST DESC="'SkUnloadDt'" ISLIST="YES" TYPE="Date" INDEX="5561">
       <UDF:SKUNLOADDT DESC="'SkUnloadDt'">${UnloadedDate ? formatDate(UnloadedDate) : ''}</UDF:SKUNLOADDT>
      </UDF:SKUNLOADDT.LIST>
          <UDF:TRANSPORTREMARKS.LIST DESC="'TransportRemarks'" ISLIST="YES" TYPE="String" INDEX="4175">
       <UDF:TRANSPORTREMARKS DESC="'TransportRemarks'">${UnloadedRemark}</UDF:TRANSPORTREMARKS>
      </UDF:TRANSPORTREMARKS.LIST>
      <UDF:TRANSPORTRECEIPTDATE.LIST DESC="'TransportReceiptDate'" ISLIST="YES" TYPE="Date" INDEX="4174">
       <UDF:TRANSPORTRECEIPTDATE DESC="'TransportReceiptDate'">${NewReceiptDate ? formatDate(NewReceiptDate) : ''}</UDF:TRANSPORTRECEIPTDATE>
      </UDF:TRANSPORTRECEIPTDATE.LIST>
      <UDF:UPDATERECEPITREMARK.LIST DESC="'UpdateRecepitRemark'" ISLIST="YES" TYPE="String" INDEX="8895">
       <UDF:UPDATERECEPITREMARK DESC="'UpdateRecepitRemark'">${ReceiptRemarks}</UDF:UPDATERECEPITREMARK>
      </UDF:UPDATERECEPITREMARK.LIST>

                                </STOCKITEM>
                            </TALLYMESSAGE>
                        </REQUESTDATA>
                    </IMPORTDATA>
                </BODY>
            </ENVELOPE>`;

        // Make Tally API request
        try {
            const response = await axios.post('http://localhost:12000', tallyRequestXML, {
                headers: { 'Content-Type': 'text/xml' }
            });
            // console.log(tallyRequestXML);

            if (response.status === 200) {
                res.status(200).json({ 
                    message: "GC data and Tally entry Updated successfully",
                    companyId: parseInt(companyId, 10),
                    branchId: branchId ? parseInt(branchId, 10) : null
                });
            } else {
                res.status(500).json({ error: "Failed to updated Tally entry" });
            }
        } catch (tallyError) {
            console.error("Tally request error:", tallyError);
            res.status(500).json({ error: "Failed to updated Tally entry" });
        }
    });
});

function formatDate1(dateStr) {
    const date = new Date(dateStr);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0'); // Months are zero-based
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}${month}${day}`;
}

router.put('/updateGC/:GcNumber', gcUpload.array('attachments', 10), (req, res) => {
    const requestId = `GC_UPDATE_${Date.now()}`;
    const requestStartTime = new Date();
    const GcNumber = req.params.GcNumber;
    
    console.log(`[${new Date().toISOString()}] [${requestId}] Starting GC update for GcNumber: ${GcNumber}`, {
        body: req.body,
        ip: req.ip,
        userAgent: req.get('user-agent')
    });

    const {
        Branch, BranchCode, GcDate, TruckNumber, vechileNumber, TruckType, BrokerNameShow, BrokerName,
        TruckFrom, TruckTo, PaymentDetails, LcNo, DeliveryDate, EBillDate, EBillExpDate, 
        DriverNameShow, DriverName, DriverPhoneNumber, CompanyId,
        Consignor, ConsignorName, ConsignorAddress, ConsignorGst, Consignee, ConsigneeName,
        ConsigneeAddress, ConsigneeGst, BillTo, BillToName, BillToAddress, BillToGst,
        CustInvNo, InvValue, EInv, EInvDate, Eda, 
        NumberofPkg, MethodofPkg, ActualWeightKgs, NumberofPkg2, MethodofPkg2, ActualWeightKgs2, 
        km, km2, km3, km4, NumberofPkg3, MethodofPkg3, ActualWeightKgs3, 
        NumberofPkg4, MethodofPkg4, ActualWeightKgs4, PrivateMark, PrivateMark2, 
        PrivateMark3, PrivateMark4, Charges, Charges2, Charges3, Charges4, 
        GoodContain, GoodContain2, GoodContain3, GoodContain4, Rate, Total, 
        Rate2, Total2, Rate3, Total3, Rate4, Total4, PoNumber, TripId,
        DeliveryFromSpecial, DeliveryAddress, ServiceTax, ReceiptBillNo, 
        ReceiptBillNoAmount, ReceiptBillNoDate, TotalRate, TotalWeight,
        HireAmount, AdvanceAmount, BalanceAmount, FreightCharge, branch_id
    } = req.body;

    // Input validation
    if (!CompanyId) {
        const errorMsg = 'CompanyId is required';
        console.error(`[${new Date().toISOString()}] [${requestId}] Validation failed: ${errorMsg}`);
        console.error(`[${new Date().toISOString()}] [${requestId}] ${errorMsg}`);
        console.log(`[${new Date().toISOString()}] [${requestId}] Response: 400 - ${errorMsg}`);
        return res.status(400).json({ 
            success: false,
            message: errorMsg,
            requestId
        });
    }

    // First check if GC exists
    db.query(
        'SELECT Id FROM gc_creation WHERE CompanyId = ? AND GcNumber = ?', 
        [CompanyId, GcNumber],
        (err, rows) => {
            if (err) {
                console.error(`[${new Date().toISOString()}] [${requestId}] Database error checking GC existence:`, {
                    error: err.message,
                    stack: err.stack
                });
                console.log(`[${new Date().toISOString()}] [${requestId}] Response: 500 - Database error`);
                return res.status(500).json({ 
                    success: false,
                    message: 'Database error',
                    requestId
                });
            }

            if (rows.length === 0) {
                const errorMsg = `GC number ${GcNumber} not found in company ${CompanyId}`;
                console.warn(`[${new Date().toISOString()}] [${requestId}] ${errorMsg}`);
                console.log(`[${new Date().toISOString()}] [${requestId}] Response: 404 - ${errorMsg}`);
                return res.status(404).json({ 
                    success: false,
                    message: errorMsg,
                    requestId
                });
            }

            // Proceed with update
            const sql = `UPDATE gc_creation SET 
                Branch=?, BranchCode=?, GcDate=?, TruckNumber=?, vechileNumber=?, 
                TruckType=?, BrokerNameShow=?, BrokerName=?, TruckFrom=?, TruckTo=?, 
                PaymentDetails=?, LcNo=?, DeliveryDate=?, EBillDate=?, EBillExpDate=?, 
                DriverNameShow=?, DriverName=?, DriverPhoneNumber=?, Consignor=?, 
                ConsignorName=?, ConsignorAddress=?, ConsignorGst=?, Consignee=?, 
                ConsigneeName=?, ConsigneeAddress=?, ConsigneeGst=?, CustInvNo=?, 
                InvValue=?, EInv=?, EInvDate=?, Eda=IFNULL(?, ''), NumberofPkg=?, 
                MethodofPkg=?, ActualWeightKgs=?, NumberofPkg2=?, MethodofPkg2=?, 
                ActualWeightKgs2=?, km=?, km2=?, km3=?, km4=?, NumberofPkg3=?, 
                MethodofPkg3=?, ActualWeightKgs3=?, NumberofPkg4=?, MethodofPkg4=?, 
                ActualWeightKgs4=?, PrivateMark=?, PrivateMark2=?, PrivateMark3=?, 
                PrivateMark4=?, Charges=?, Charges2=?, Charges3=?, Charges4=?, 
                GoodContain=?, GoodContain2=?, GoodContain3=?, GoodContain4=?, 
                Rate=?, Total=?, Rate2=?, Total2=?, Rate3=?, Total3=?, Rate4=?, 
                Total4=?, PoNumber=?, TripId=?, DeliveryFromSpecial=?, DeliveryAddress=?, 
                ServiceTax=?, ReceiptBillNo=?, ReceiptBillNoAmount=?, ReceiptBillNoDate=?, 
                TotalRate=?, TotalWeight=?, HireAmount=?, AdvanceAmount=?, 
                BalanceAmount=?, FreightCharge=?, branch_id=?, updated_at=CURRENT_TIMESTAMP 
                WHERE CompanyId=? AND GcNumber=?`;

            const values = [
                Branch, BranchCode, GcDate, TruckNumber, vechileNumber, TruckType, 
                BrokerNameShow, BrokerName, TruckFrom, TruckTo, PaymentDetails, LcNo, 
                DeliveryDate, EBillDate, EBillExpDate, DriverNameShow, DriverName, 
                DriverPhoneNumber, Consignor, ConsignorName, ConsignorAddress, 
                ConsignorGst, Consignee, ConsigneeName, ConsigneeAddress, ConsigneeGst, 
                BillTo, BillToName, BillToAddress, BillToGst, CustInvNo, 
                InvValue, EInv, EInvDate, Eda, NumberofPkg, MethodofPkg, 
                ActualWeightKgs, NumberofPkg2, MethodofPkg2, ActualWeightKgs2, 
                km, km2, km3, km4, NumberofPkg3, MethodofPkg3, ActualWeightKgs3, 
                NumberofPkg4, MethodofPkg4, ActualWeightKgs4, PrivateMark, PrivateMark2, 
                PrivateMark3, PrivateMark4, Charges, Charges2, Charges3, Charges4, 
                GoodContain, GoodContain2, GoodContain3, GoodContain4, Rate, Total, 
                Rate2, Total2, Rate3, Total3, Rate4, Total4, PoNumber, TripId,
                DeliveryFromSpecial, DeliveryAddress, ServiceTax, ReceiptBillNo, 
                ReceiptBillNoAmount, ReceiptBillNoDate, TotalRate, TotalWeight,
                HireAmount, AdvanceAmount, BalanceAmount, FreightCharge,
                branch_id, CompanyId, GcNumber
            ];

            // Execute the update
            db.query(sql, values, (err, result) => {
                if (err) {
                    console.error(`[${new Date().toISOString()}] [${requestId}] Database update error:`, {
                        error: err.message,
                        stack: err.stack,
                        sql: sql.substring(0, 200) + '...',
                        valuesCount: values.length
                    });
                    console.log(`[${new Date().toISOString()}] [${requestId}] Response: 500 - Failed to update GC`);
                    return res.status(500).json({
                        success: false,
                        message: 'Failed to update GC',
                        error: process.env.NODE_ENV === 'development' ? err.message : undefined,
                        requestId
                    });
                }

                console.log(`[${new Date().toISOString()}] [${requestId}] Successfully updated GC`, {
                    GcNumber,
                    CompanyId,
                    rowsAffected: result.affectedRows,
                    processingTime: `${new Date() - requestStartTime}ms`
                });

                // Process uploaded files if any
                if (req.files && req.files.length > 0) {
                    // First, fetch existing attachments
                    const fetchExistingSql = 'SELECT attachment_files FROM gc_creation WHERE GcNumber = ? AND CompanyId = ?';
                    db.query(fetchExistingSql, [GcNumber, CompanyId], (fetchErr, fetchResult) => {
                        let attachmentFiles = [];
                        if (fetchErr) {
                            console.error(`[${new Date().toISOString()}] [${requestId}] Error fetching existing attachments:`, fetchErr);
                            // Continue with just new files if fetch fails
                            attachmentFiles = req.files.map(file => ({
                                filename: file.filename,
                                originalName: file.originalname,
                                mimeType: file.mimetype,
                                size: file.size,
                                uploadDate: new Date().toISOString(),
                                uploadedBy: req.query.userId || 'unknown'
                            }));
                        } else {
                            // Parse existing attachments
                            let existingAttachments = [];
                            if (fetchResult.length > 0 && fetchResult[0].attachment_files) {
                                try {
                                    existingAttachments = JSON.parse(fetchResult[0].attachment_files);
                                } catch (parseErr) {
                                    console.error(`[${new Date().toISOString()}] [${requestId}] Error parsing existing attachments:`, parseErr);
                                }
                            }

                            // Create new attachment objects
                            const newAttachments = req.files.map(file => ({
                                filename: file.filename,
                                originalName: file.originalname,
                                mimeType: file.mimetype,
                                size: file.size,
                                uploadDate: new Date().toISOString(),
                                uploadedBy: req.query.userId || 'unknown'
                            }));

                            // Combine existing and new attachments
                            attachmentFiles = [...existingAttachments, ...newAttachments];
                        }

                        // Update the GC record with combined attachment information
                        const updateSql = 'UPDATE gc_creation SET attachment_files = ?, attachment_count = ? WHERE GcNumber = ? AND CompanyId = ?';
                        db.query(updateSql, [JSON.stringify(attachmentFiles), attachmentFiles.length, GcNumber, CompanyId], (updateErr) => {
                            if (updateErr) {
                                console.error(`[${new Date().toISOString()}] [${requestId}] Error updating GC with attachments:`, updateErr);
                                // Don't fail the request, just log the error
                            } else {
                                console.log(`[${new Date().toISOString()}] [${requestId}] Successfully updated GC with ${attachmentFiles.length} attachments`);
                            }

                            console.log(`[${new Date().toISOString()}] [${requestId}] Response: 200 - GC updated successfully`);
                            return res.status(200).json({
                                success: true,
                                message: 'GC updated successfully',
                                data: {
                                    GcNumber,
                                    CompanyId,
                                    updated: true,
                                    attachments: attachmentFiles,
                                    attachmentCount: attachmentFiles.length
                                },
                                requestId
                            });
                        });
                    });
                } else {
                    console.log(`[${new Date().toISOString()}] [${requestId}] Response: 200 - GC updated successfully`);
                    return res.status(200).json({
                        success: true,
                        message: 'GC updated successfully',
                        data: {
                            GcNumber,
                            CompanyId,
                            updated: true,
                            attachments: [],
                            attachmentCount: 0
                        },
                        requestId
                    });
                }
            });
        }
    );
});

router.post('/add', gcUpload.array('attachments', 10), (req, res) => {
    const requestId = `GC_ADD_${Date.now()}`;
    const requestStartTime = new Date();
    
    // Get userId from query parameters
    const userId = req.query.userId;
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional
    const gcData = req.body;
    
    // Validate userId is provided
    if (!userId) {
        console.log(`[${new Date().toISOString()}] [${requestId}] Validation failed: User ID is required`);
        console.log(`[${new Date().toISOString()}] [${requestId}] Response: 400 - User ID is required as a query parameter`);
        return res.status(400).json({
            success: false,
            message: 'User ID is required as a query parameter',
            requestId
        });
    }

    if (!companyId) {
        console.log(`[${new Date().toISOString()}] [${requestId}] Validation failed: companyId is required`);
        console.log(`[${new Date().toISOString()}] [${requestId}] Response: 400 - companyId is required as a query parameter`);
        return res.status(400).json({
            success: false,
            message: 'companyId is required as a query parameter',
            requestId
        });
    }

    // Validate user belongs to the specified company
    db.query('SELECT branch_id FROM profile_picture WHERE userId = ? AND companyId = ?', [userId, companyId], (userErr, userResult) => {
        if (userErr) {
            console.error(`[${new Date().toISOString()}] [${requestId}] Database error checking user:`, userErr);
            return res.status(500).json({
                success: false,
                message: 'Database error checking user',
                requestId
            });
        }
        if (userResult.length === 0) {
            console.log(`[${new Date().toISOString()}] [${requestId}] Validation failed: User does not belong to company ${companyId}`);
            console.log(`[${new Date().toISOString()}] [${requestId}] Response: 403 - Access denied. User does not belong to this company.`);
            return res.status(403).json({
                success: false,
                message: 'Access denied. User does not belong to this company.',
                requestId
            });
        }

        // Validate branch access if specified
        if (branchId) {
            const userBranchId = userResult[0].branch_id;
            if (userBranchId === null) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User is not assigned to any branch.',
                    requestId
                });
            }
            if (parseInt(userBranchId) !== parseInt(branchId)) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. User does not belong to this branch.',
                    requestId
                });
            }
        }

        // Log the incoming request
        console.log(`[${new Date().toISOString()}] [${requestId}] New GC creation request received`, {
            ip: req.ip,
            userAgent: req.get('user-agent'),
            userId,
            companyId,
            branchId,
            body: {
                GcNumber: gcData.GcNumber,
                CompanyId: gcData.CompanyId,
                ConsignorName: gcData.ConsignorName,
                ConsigneeName: gcData.ConsigneeName,
                TruckFrom: gcData.TruckFrom,
                TruckTo: gcData.TruckTo,
                TruckNumber: gcData.TruckNumber,
                GcDate: gcData.GcDate
            }
        });
        
        // Validate userId
        if (!userId) {
            const errorMsg = 'User ID is required';
            console.error(`[${new Date().toISOString()}] [${requestId}] Validation failed: ${errorMsg}`);
            return res.status(400).json({ 
                success: false,
                message: errorMsg,
                requestId
            });
        }

        // Destructure all GC data from the request body (excluding userId which we already extracted)
        const {
            Branch, BranchCode, GcNumber, GcDate, TruckNumber, vechileNumber, TruckType, BrokerNameShow, BrokerName,
            TruckFrom, TruckTo, PaymentDetails, LcNo, DeliveryDate, EBillDate, EBillExpDate, DriverNameShow, DriverName, DriverPhoneNumber,
            Consignor, ConsignorName, ConsignorAddress, ConsignorGst, Consignee, ConsigneeName,
            ConsigneeAddress, ConsigneeGst, BillTo, BillToName, BillToAddress, BillToGst,
            CustInvNo, InvValue, EInv, EInvDate, Eda, NumberofPkg,
            MethodofPkg, ActualWeightKgs, NumberofPkg2, MethodofPkg2, ActualWeightKgs2, km, km2, km3, km4,
            NumberofPkg3, MethodofPkg3, ActualWeightKgs3, NumberofPkg4, MethodofPkg4, ActualWeightKgs4,
            PrivateMark, PrivateMark2, PrivateMark3, PrivateMark4, Charges, Charges2, Charges3, Charges4, 
            GoodContain, GoodContain2, GoodContain3, GoodContain4, Rate, Total, Rate2, Total2, Rate3, Total3, Rate4, Total4, 
            PoNumber, TripId, DeliveryFromSpecial, DeliveryAddress, ServiceTax, ReceiptBillNo, ReceiptBillNoAmount, 
            ReceiptBillNoDate, TotalRate, TotalWeight, HireAmount, AdvanceAmount, BalanceAmount, FreightCharge, 
            Day1, Day1Place, Day2, Day3, Day4, Day5, Day6, Day7, Day8, CompanyId, branch_id
        } = gcData;

        // Input validation
        if (!GcNumber || !CompanyId) {
            const errorMsg = 'Missing required fields: GcNumber and CompanyId are required';
            console.error(`[${new Date().toISOString()}] [${requestId}] Validation failed: ${errorMsg}`, {
                received: { GcNumber, CompanyId },
                required: ['GcNumber', 'CompanyId']
            });
            return res.status(400).json({ 
                success: false,
                message: errorMsg,
                requestId
            });
        }

        // Check for duplicate GC number
        db.query('SELECT * FROM gc_creation WHERE CompanyId = ? AND GcNumber = ?', 
        [CompanyId, GcNumber], 
        (err, rows) => {
            if (err) {
                console.error(`[${new Date().toISOString()}] [${requestId}] Database error when checking for duplicate GC number`, {
                    error: err.message,
                    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
                    query: 'SELECT * FROM gc_creation WHERE CompanyId = ? AND GcNumber = ?',
                    params: [CompanyId, GcNumber]
                });
                return res.status(500).json({ 
                    success: false,
                    message: 'Database error when checking for duplicate GC number',
                    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
                    requestId
                });
            }

            if (rows.length > 0) {
                const errorMsg = `GC number ${GcNumber} already exists in company ${CompanyId}`;
                console.warn(`[${new Date().toISOString()}] [${requestId}] ${errorMsg}`);
                return res.status(400).json({ 
                    success: false,
                    message: errorMsg,
                    requestId
                });
            }

            // Prepare SQL and values for insertion while keeping column/value counts aligned
            const insertData = {
                Branch,
                BranchCode,
                GcNumber,
                GcDate,
                TruckNumber,
                vechileNumber,
                TruckType,
                BrokerNameShow,
                BrokerName,
                TruckFrom,
                TruckTo,
                PaymentDetails,
                LcNo,
                DeliveryDate,
                EBillDate,
                EBillExpDate,
                DriverNameShow,
                DriverName,
                DriverPhoneNumber,
                Consignor,
                ConsignorName,
                ConsignorAddress,
                ConsignorGst,
                Consignee,
                ConsigneeName,
                ConsigneeAddress,
                ConsigneeGst,
                BillTo,
                BillToName,
                BillToAddress,
                BillToGst,
                CustInvNo,
                InvValue,
                EInv,
                EInvDate,
                Eda,
                NumberofPkg,
                MethodofPkg,
                ActualWeightKgs,
                NumberofPkg2,
                MethodofPkg2,
                ActualWeightKgs2,
                km,
                km2,
                km3,
                km4,
                NumberofPkg3,
                MethodofPkg3,
                ActualWeightKgs3,
                NumberofPkg4,
                MethodofPkg4,
                ActualWeightKgs4,
                PrivateMark,
                PrivateMark2,
                PrivateMark3,
                PrivateMark4,
                Charges,
                Charges2,
                Charges3,
                Charges4,
                GoodContain,
                GoodContain2,
                GoodContain3,
                GoodContain4,
                Rate,
                Total,
                Rate2,
                Total2,
                Rate3,
                Total3,
                Rate4,
                Total4,
                PoNumber,
                TripId,
                DeliveryFromSpecial,
                DeliveryAddress,
                ServiceTax,
                ReceiptBillNo,
                ReceiptBillNoAmount,
                ReceiptBillNoDate,
                TotalRate,
                TotalWeight,
                HireAmount,
                AdvanceAmount,
                BalanceAmount,
                FreightCharge,
                Day1,
                Day1Place,
                CompanyId,
                branch_id,
                send_to_tally: 'no'
            };

            const insertColumns = Object.keys(insertData);
            const sql = `INSERT INTO gc_creation (${insertColumns.join(', ')}) VALUES (${insertColumns.map(() => '?').join(', ')})`;
            const values = insertColumns.map((column) => insertData[column] ?? null);

            // Log the insert operation
            console.log(`[${new Date().toISOString()}] [${requestId}] Attempting to insert new GC record`, {
                GcNumber,
                CompanyId,
                ConsignorName,
                ConsigneeName,
                TruckFrom,
                TruckTo,
                TruckNumber,
                GcDate,
                TotalWeight,
                TotalRate
            });

            // Execute the insert query
            db.query(sql, values, (err, result) => {
                const queryEndTime = new Date();
                const queryDuration = queryEndTime - requestStartTime;
                
                if (err) {
                    console.error(`[${new Date().toISOString()}] [${requestId}] Database error when inserting GC record`, {
                        error: err.message,
                        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
                        query: sql.substring(0, 200) + '...', // Log first 200 chars of SQL
                        params: values.map(v => 
                            typeof v === 'string' && v.length > 50 ? v.substring(0, 50) + '...' : v
                        ),
                        duration: `${queryDuration}ms`
                    });
                    
                    return res.status(500).json({ 
                        success: false,
                        message: 'Failed to add GC record',
                        error: process.env.NODE_ENV === 'development' ? err.message : undefined,
                        requestId
                    });
                }
                
                // Calculate total time taken
                const totalTime = new Date() - requestStartTime;
                
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

                    // Update the GC record with attachment information
                    const updateSql = 'UPDATE gc_creation SET attachment_files = ?, attachment_count = ? WHERE Id = ? AND CompanyId = ?';
                    db.query(updateSql, [JSON.stringify(attachmentFiles), attachmentFiles.length, result.insertId, companyId], (updateErr) => {
                        if (updateErr) {
                            console.error(`[${new Date().toISOString()}] [${requestId}] Error updating GC with attachments:`, updateErr);
                            // Don't fail the request, just log the error
                        }
                    });
                }
                
                // Log successful insertion
                console.log(`[${new Date().toISOString()}] [${requestId}] Successfully created GC record`, {
                    gcId: result.insertId,
                    GcNumber,
                    CompanyId,
                    attachmentsCount: attachmentFiles.length,
                    queryDuration: `${queryDuration}ms`,
                    totalDuration: `${totalTime}ms`,
                    affectedRows: result.affectedRows
                });
                
                // Call gc-management/submit-gc endpoint
                console.log(`[${new Date().toISOString()}] [${requestId}] Calling gc-management/submit-gc for userId: ${userId}`);
                
                // Make a POST request to the submit-gc endpoint
                const axios = require('axios');
                axios.post(`${config.api.baseUrl}/gc-management/submit-gc`, { 
                    userId, 
                    companyId: parseInt(companyId, 10), 
                    branchId: branchId ? parseInt(branchId, 10) : null 
                })
                    .then(response => {
                        console.log(`[${new Date().toISOString()}] [${requestId}] Successfully called submit-gc endpoint`, {
                            status: response.status,
                            data: response.data
                        });
                        console.log(`[${new Date().toISOString()}] [${requestId}] Response: 201 - GC record added and submitted successfully`);
                        // Success response with the inserted record details and submit-gc response
                        return res.status(201).json({
                            success: true,
                            message: 'GC record added and submitted successfully',
                            requestId,
                            data: {
                                id: result.insertId,
                                gcNumber: GcNumber,
                                sendToTally: 'no',
                                timestamp: new Date().toISOString(),
                                duration: `${new Date() - requestStartTime}ms`,
                                submitGcResponse: response.data,
                                attachments: attachmentFiles,
                                attachmentCount: attachmentFiles.length,
                                companyId: parseInt(companyId, 10),
                                branchId: branchId ? parseInt(branchId, 10) : null
                            }
                        });
                    })
                    .catch(error => {
                        console.error(`[${new Date().toISOString()}] [${requestId}] Error calling submit-gc endpoint:`, {
                            error: error.message,
                            response: error.response ? {
                                status: error.response.status,
                                data: error.response.data
                            } : 'No response',
                            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
                        });
                        console.log(`[${new Date().toISOString()}] [${requestId}] Response: 201 - GC record added but there was an error submitting it`);
                        // Even if submit-gc fails, we still respond with success since the GC was created
                        // but include the error information in the response
                        return res.status(201).json({
                            success: true,
                            message: 'GC record added but there was an error submitting it',
                            requestId,
                            data: {
                                id: result.insertId,
                                gcNumber: GcNumber,
                                sendToTally: 'no',
                                timestamp: new Date().toISOString(),
                                duration: `${new Date() - requestStartTime}ms`,
                                error: {
                                    message: 'Failed to submit GC',
                                    details: error.response ? error.response.data : error.message
                                },
                                attachments: attachmentFiles,
                                attachmentCount: attachmentFiles.length,
                                companyId: parseInt(companyId, 10),
                                branchId: branchId ? parseInt(branchId, 10) : null
                            },
                            warning: 'GC was created but there was an error submitting it'
                        });
                    });
            });
        });
    });
});


// Helper function to format date for Tally
function formatDateForTally(dateString) {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        // Check if date is valid
        if (isNaN(date.getTime())) return '';
        
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        
        // Tally expects YYYYMMDD format
        return `${year}${month}${day}`;
    } catch (e) {
        console.error('Error formatting date:', e);
        return '';
    }
}

// Helper function to execute a query with promises
const query = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.query(sql, params, (error, results) => {
            if (error) return reject(error);
            resolve(results);
        });
    });
};

// Helper function to parse Tally XML response
function parseTallyResponse(xmlResponse) {
    try {
        // Extract values using regex
        const created = xmlResponse.match(/<CREATED>(\d+)<\/CREATED>/)?.[1] || '0';
        const altered = xmlResponse.match(/<ALTERED>(\d+)<\/ALTERED>/)?.[1] || '0';
        const deleted = xmlResponse.match(/<DELETED>(\d+)<\/DELETED>/)?.[1] || '0';
        const ignored = xmlResponse.match(/<IGNORED>(\d+)<\/IGNORED>/)?.[1] || '0';
        const errors = xmlResponse.match(/<ERRORS>(\d+)<\/ERRORS>/)?.[1] || '0';
        const cancelled = xmlResponse.match(/<CANCELLED>(\d+)<\/CANCELLED>/)?.[1] || '0';
        const exceptions = xmlResponse.match(/<EXCEPTIONS>(\d+)<\/EXCEPTIONS>/)?.[1] || '0';

        return {
            created: parseInt(created),
            altered: parseInt(altered),
            deleted: parseInt(deleted),
            ignored: parseInt(ignored),
            errors: parseInt(errors),
            cancelled: parseInt(cancelled),
            exceptions: parseInt(exceptions)
        };
    } catch (error) {
        console.error('Error parsing Tally response:', error);
        return null;
    }
}


// Endpoint to fetch and process records for Tally
router.get('/push-to-tally', async (req, res) => {
    try {
        const companyId = req.query.companyId;
        const branchId = req.query.branchId; // Optional branch filter

        if (!companyId) {
            return res.status(400).json({ error: 'companyId is required' });
        }

        // Build query to filter by company and optional branch
        let query = 'SELECT * FROM gc_creation WHERE send_to_tally = ? AND CompanyId = ?';
        let params = ['no', companyId];

        if (branchId) {
            query += ' AND branch_id = ?';
            params.push(branchId);
        }

        // Fetch all records where send_to_tally is 'no' for the specified company
        const pendingRecords = await query(query, params);

        if (pendingRecords.length === 0) {
            return res.status(200).json({
                success: true,
                message: 'No pending records to sync with Tally',
                data: [],
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            });
        }

        // Process each record for Tally
        const results = [];
        
        for (const record of pendingRecords) {
            try {

                // Create Tally XML with the provided template
                const tallyRequestXML = `
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Import Data</TALLYREQUEST>
 </HEADER>
 <BODY>
  <IMPORTDATA>
   <REQUESTDESC>
    <REPORTNAME>All Masters</REPORTNAME>
    <STATICVARIABLES>
     <SVCURRENTCOMPANY>Dummy</SVCURRENTCOMPANY>
    </STATICVARIABLES>
   </REQUESTDESC>
   <REQUESTDATA>
    <TALLYMESSAGE xmlns:UDF="TallyUDF">
     <STOCKITEM NAME="${record.GcNumber}" RESERVEDNAME="">
      <LANGUAGENAME.LIST>
       <NAME.LIST TYPE="String">
        <NAME>${record.GcNumber}</NAME>
       </NAME.LIST>
       <LANGUAGEID> 1033</LANGUAGEID>
      </LANGUAGENAME.LIST>
      <UDF:TRANSDAYS.LIST DESC="'TransDays'" ISLIST="YES" TYPE="String" INDEX="5583">
       <UDF:TRANSDAYS DESC="'TransDays'">${record.Eda || ''}</UDF:TRANSDAYS>
      </UDF:TRANSDAYS.LIST>
      <UDF:SKHIGHDTS.LIST DESC="'SkHighDts'" ISLIST="YES" TYPE="Amount" INDEX="5556">
       <UDF:SKHIGHDTS DESC="'SkHighDts'">${record.HireAmount || 0}</UDF:SKHIGHDTS>
      </UDF:SKHIGHDTS.LIST>
      <UDF:SKADVDTS.LIST DESC="'SkAdvDts'" ISLIST="YES" TYPE="Amount" INDEX="5557">
       <UDF:SKADVDTS DESC="'SkAdvDts'">${record.AdvanceAmount || 0}</UDF:SKADVDTS>
      </UDF:SKADVDTS.LIST>
      <UDF:SKBALDTS.LIST DESC="'SkBalDts'" ISLIST="YES" TYPE="Amount" INDEX="5558">
       <UDF:SKBALDTS DESC="'SkBalDts'">${record.BalanceAmount || 0}</UDF:SKBALDTS>
      </UDF:SKBALDTS.LIST>
      <UDF:SKFRIVALUE.LIST DESC="'SkFriValue'" ISLIST="YES" TYPE="Amount" INDEX="5559">
       <UDF:SKFRIVALUE DESC="'SkFriValue'">${record.FreightCharge || 0}</UDF:SKFRIVALUE>
      </UDF:SKFRIVALUE.LIST>
      <UDF:TRANSRATEFIELD.LIST DESC="'TransRateField'" ISLIST="YES" TYPE="Amount" INDEX="9869">
       <UDF:TRANSRATEFIELD DESC="'TransRateField'">${record.Rate || 0}</UDF:TRANSRATEFIELD>
      </UDF:TRANSRATEFIELD.LIST>
      <UDF:TRANWGTSRTCALCFIELD.LIST DESC="'TranWgtsRtCalcField'" ISLIST="YES" TYPE="Amount" INDEX="9870">
       <UDF:TRANWGTSRTCALCFIELD DESC="'TranWgtsRtCalcField'">4000.00</UDF:TRANWGTSRTCALCFIELD>
      </UDF:TRANWGTSRTCALCFIELD.LIST>
      <UDF:SHIPPINGDATE.LIST DESC="'Shipping Date''Tripdate'" ISLIST="YES" TYPE="Date" INDEX="2">
       <UDF:SHIPPINGDATE DESC="'Shipping Date''Tripdate'">${record.GcDate ? formatDateForTally(record.GcDate) : ''}</UDF:SHIPPINGDATE>
      </UDF:SHIPPINGDATE.LIST>
      <UDF:SKUNLOADDT.LIST DESC="'SkUnloadDt'" ISLIST="YES" TYPE="Date" INDEX="5561">
       <UDF:SKUNLOADDT DESC="'SkUnloadDt'"></UDF:SKUNLOADDT>
      </UDF:SKUNLOADDT.LIST>
      <UDF:SKDELDY1DT.LIST DESC="'SkDelDy1Dt'" ISLIST="YES" TYPE="Date" INDEX="5562">
       <UDF:SKDELDY1DT DESC="'SkDelDy1Dt'">${record.Day1 ? formatDateForTally(record.Day1) : (record.GcDate ? formatDateForTally(record.GcDate) : '')}</UDF:SKDELDY1DT>
      </UDF:SKDELDY1DT.LIST>
      <UDF:SKDELDY2DT.LIST DESC="'SkDelDy2Dt'" ISLIST="YES" TYPE="Date" INDEX="5564">
       <UDF:SKDELDY2DT DESC="'SkDelDy2Dt'">${record.Day2 ? formatDateForTally(record.Day2) : ''}</UDF:SKDELDY2DT>
      </UDF:SKDELDY2DT.LIST>
      <UDF:SKDELDY3DT.LIST DESC="'SkDelDy3Dt'" ISLIST="YES" TYPE="Date" INDEX="5566">
       <UDF:SKDELDY3DT DESC="'SkDelDy3Dt'">${record.Day3 ? formatDateForTally(record.Day3) : ''}</UDF:SKDELDY3DT>
      </UDF:SKDELDY3DT.LIST>
      <UDF:SKDELDY4DT.LIST DESC="'SkDelDy4Dt'" ISLIST="YES" TYPE="Date" INDEX="5568">
       <UDF:SKDELDY4DT DESC="'SkDelDy4Dt'">${record.Day4 ? formatDateForTally(record.Day4) : ''}</UDF:SKDELDY4DT>
      </UDF:SKDELDY4DT.LIST>
      <UDF:SKDELDY5DT.LIST DESC="'SkDelDy5Dt'" ISLIST="YES" TYPE="Date" INDEX="5570">
       <UDF:SKDELDY5DT DESC="'SkDelDy5Dt'">${record.Day5 ? formatDateForTally(record.Day5) : ''}</UDF:SKDELDY5DT>
      </UDF:SKDELDY5DT.LIST>
      <UDF:SKDELDY6DT.LIST DESC="'SkDelDy6Dt'" ISLIST="YES" TYPE="Date" INDEX="5572">
       <UDF:SKDELDY6DT DESC="'SkDelDy6Dt'">${record.Day6 ? formatDateForTally(record.Day6) : ''}</UDF:SKDELDY6DT>
      </UDF:SKDELDY6DT.LIST>
      <UDF:SKDELDY7DT.LIST DESC="'SkDelDy7Dt'" ISLIST="YES" TYPE="Date" INDEX="5574">
       <UDF:SKDELDY7DT DESC="'SkDelDy7Dt'">${record.Day7 ? formatDateForTally(record.Day7) : ''}</UDF:SKDELDY7DT>
      </UDF:SKDELDY7DT.LIST>
      <UDF:SKDELDY8DT.LIST DESC="'SkDelDy8Dt'" ISLIST="YES" TYPE="Date" INDEX="5581">
       <UDF:SKDELDY8DT DESC="'SkDelDy8Dt'">${record.Day8 ? formatDateForTally(record.Day8) : ''}</UDF:SKDELDY8DT>
      </UDF:SKDELDY8DT.LIST>
      <UDF:TRANSDELDATE.LIST DESC="'TransDelDate'" ISLIST="YES" TYPE="Date" INDEX="5584">
       <UDF:TRANSDELDATE DESC="'TransDelDate'">${record.DeliveryDate ? formatDateForTally(record.DeliveryDate) : ''}</UDF:TRANSDELDATE>
      </UDF:TRANSDELDATE.LIST>
      <UDF:EWAYBILLDTFLD.LIST DESC="'EwayBillDtFld'" ISLIST="YES" TYPE="Date" INDEX="9866">
       <UDF:EWAYBILLDTFLD DESC="'EwayBillDtFld'">${record.EBillExpDate ? formatDateForTally(record.EBillExpDate) : ''}</UDF:EWAYBILLDTFLD>
      </UDF:EWAYBILLDTFLD.LIST>
      <UDF:NOOFPKG.LIST DESC="'Noofpkg'" ISLIST="YES" TYPE="String" INDEX="3006">
       <UDF:NOOFPKG DESC="'Noofpkg'">${record.NumberofPkg || ''}</UDF:NOOFPKG>
      </UDF:NOOFPKG.LIST>
      <UDF:METOFPKG.LIST DESC="'MetofPkg'" ISLIST="YES" TYPE="String" INDEX="3007">
       <UDF:METOFPKG DESC="'MetofPkg'">${record.MethodofPkg || ''}</UDF:METOFPKG>
      </UDF:METOFPKG.LIST>
      <UDF:NATOFGOOD.LIST DESC="'Natofgood'" ISLIST="YES" TYPE="String" INDEX="3008">
       <UDF:NATOFGOOD DESC="'Natofgood'">${record.GoodContain || ''}</UDF:NATOFGOOD>
      </UDF:NATOFGOOD.LIST>
      <UDF:ACTWGTKGS.LIST DESC="'ActWgtKgs'" ISLIST="YES" TYPE="String" INDEX="3009">
       <UDF:ACTWGTKGS DESC="'ActWgtKgs'">${record.ActualWeightKgs || ''}</UDF:ACTWGTKGS>
      </UDF:ACTWGTKGS.LIST>
      <UDF:PRIVATEMARKS.LIST DESC="'PrivateMarks'" ISLIST="YES" TYPE="String" INDEX="3010">
       <UDF:PRIVATEMARKS DESC="'PrivateMarks'">${record.PrivateMark || ''}</UDF:PRIVATEMARKS>
      </UDF:PRIVATEMARKS.LIST>
      <UDF:CHARGESFOR.LIST DESC="'Chargesfor'" ISLIST="YES" TYPE="String" INDEX="3011">
       <UDF:CHARGESFOR DESC="'Chargesfor'">${record.Charges || ''}</UDF:CHARGESFOR>
      </UDF:CHARGESFOR.LIST>
      <UDF:CONSIGNEEADDRESS.LIST DESC="'Consignee Address'" ISLIST="YES" TYPE="String" INDEX="4152">
       <UDF:CONSIGNEEADDRESS DESC="'Consignee Address'">${record.ConsigneeAddress || ''}</UDF:CONSIGNEEADDRESS>
      </UDF:CONSIGNEEADDRESS.LIST>
      <UDF:CONSIGNEELOCATION.LIST DESC="'ConsigneeLocation'" ISLIST="YES" TYPE="String" INDEX="4153">
       <UDF:CONSIGNEELOCATION DESC="'ConsigneeLocation'">${record.TruckTo || ''}</UDF:CONSIGNEELOCATION>
      </UDF:CONSIGNEELOCATION.LIST>
      <UDF:CONSIGNORADDRESS.LIST DESC="'Consignor Address'" ISLIST="YES" TYPE="String" INDEX="4159">
       <UDF:CONSIGNORADDRESS DESC="'Consignor Address'">${record.ConsignorAddress || ''}</UDF:CONSIGNORADDRESS>
      </UDF:CONSIGNORADDRESS.LIST>
      <UDF:CONSIGNORLOCATION.LIST DESC="'ConsignorLocation'" ISLIST="YES" TYPE="String" INDEX="4160">
       <UDF:CONSIGNORLOCATION DESC="'ConsignorLocation'">${record.TruckFrom || ''}</UDF:CONSIGNORLOCATION>
      </UDF:CONSIGNORLOCATION.LIST>
      <UDF:GCLORRYNO.LIST DESC="'GcLorryNo'" ISLIST="YES" TYPE="String" INDEX="4166">
       <UDF:GCLORRYNO DESC="'GcLorryNo'">${record.TruckNumber || ''}</UDF:GCLORRYNO>
      </UDF:GCLORRYNO.LIST>
      <UDF:GCCONSINGORNAME.LIST DESC="'GCConsingorName'" ISLIST="YES" TYPE="String" INDEX="4167">
       <UDF:GCCONSINGORNAME DESC="'GCConsingorName'">${record.ConsignorName || ''}</UDF:GCCONSINGORNAME>
      </UDF:GCCONSINGORNAME.LIST>
      <UDF:TRANSPORTCUSTOMERINVOICENO.LIST DESC="'TransportCustomerInvoiceno'" ISLIST="YES" TYPE="String" INDEX="4172">
       <UDF:TRANSPORTCUSTOMERINVOICENO DESC="'TransportCustomerInvoiceno'">${record.CustInvNo || ''}</UDF:TRANSPORTCUSTOMERINVOICENO>
      </UDF:TRANSPORTCUSTOMERINVOICENO.LIST>
      <UDF:GCDRIVERNAME.LIST DESC="'GCDriverName'" ISLIST="YES" TYPE="String" INDEX="4173">
       <UDF:GCDRIVERNAME DESC="'GCDriverName'">${record.DriverNameShow || ''}</UDF:GCDRIVERNAME>
      </UDF:GCDRIVERNAME.LIST>
      <UDF:TRSDELPAIDBY.LIST DESC="'TrsDelPaidby'" ISLIST="YES" TYPE="String" INDEX="4177">
       <UDF:TRSDELPAIDBY DESC="'TrsDelPaidby'">${record.ServiceTax || ''}</UDF:TRSDELPAIDBY>
      </UDF:TRSDELPAIDBY.LIST>
      <UDF:GCBROKERNAME.LIST DESC="'GCBrokerName'" ISLIST="YES" TYPE="String" INDEX="4181">
       <UDF:GCBROKERNAME DESC="'GCBrokerName'">${record.BrokerNameShow || ''}</UDF:GCBROKERNAME>
      </UDF:GCBROKERNAME.LIST>
      <UDF:CUSTOMRPARTYNAME.LIST DESC="'CustomrPartyName'" ISLIST="YES" TYPE="String" INDEX="4182">
       <UDF:CUSTOMRPARTYNAME DESC="'CustomrPartyName'">${record.ConsigneeName || ''}</UDF:CUSTOMRPARTYNAME>
      </UDF:CUSTOMRPARTYNAME.LIST>
      <UDF:SKDELDY1LOC.LIST DESC="'SkDelDy1Loc'" ISLIST="YES" TYPE="String" INDEX="5563">
       <UDF:SKDELDY1LOC DESC="'SkDelDy1Loc'">${record.TruckFrom || ''}</UDF:SKDELDY1LOC>
      </UDF:SKDELDY1LOC.LIST>
      <UDF:TYPEOFVEHICLE.LIST DESC="'TypeOfVehicle'" ISLIST="YES" TYPE="String" INDEX="5890">
       <UDF:TYPEOFVEHICLE DESC="'TypeOfVehicle'">${record.TruckType || ''}</UDF:TYPEOFVEHICLE>
      </UDF:TYPEOFVEHICLE.LIST>
      <UDF:TRANSPORTPAYMENTDETAILS.LIST DESC="'TransPortpaymentDetails'" ISLIST="YES" TYPE="String" INDEX="8788">
       <UDF:TRANSPORTPAYMENTDETAILS DESC="'TransPortpaymentDetails'">${record.PaymentDetails || ''}</UDF:TRANSPORTPAYMENTDETAILS>
      </UDF:TRANSPORTPAYMENTDETAILS.LIST>
      <UDF:DELIVERYNAME.LIST DESC="'DeliveryName'" ISLIST="YES" TYPE="String" INDEX="8910">
       <UDF:DELIVERYNAME DESC="'DeliveryName'">${record.TruckTo || ''}</UDF:DELIVERYNAME>
      </UDF:DELIVERYNAME.LIST>
      <UDF:DELIVERYADDRESS.LIST DESC="'DeliveryAddress'" ISLIST="YES" TYPE="String" INDEX="8911">
       <UDF:DELIVERYADDRESS DESC="'DeliveryAddress'">${record.DeliveryAddress || ''}</UDF:DELIVERYADDRESS>
      </UDF:DELIVERYADDRESS.LIST>
      <UDF:TRANSPORTGCNO.LIST DESC="'TransportGCNo'" ISLIST="YES" TYPE="String" INDEX="8915">
       <UDF:TRANSPORTGCNO DESC="'TransportGCNo'">${record.GcNumber || ''}</UDF:TRANSPORTGCNO>
      </UDF:TRANSPORTGCNO.LIST>
      <UDF:LOADINGFIELD.LIST DESC="'LoadingField'" ISLIST="YES" TYPE="String" INDEX="8914">
       <UDF:LOADINGFIELD DESC="'LoadingField'">${record.DeliveryFromSpecial || ''}</UDF:LOADINGFIELD>
      </UDF:LOADINGFIELD.LIST>
      <UDF:TRANSPORTDELDATE.LIST DESC="TransportDelDate" ISLIST="YES" TYPE="Date" INDEX="9871">
       <UDF:TRANSPORTDELDATE DESC="TransportDelDate">${record.DeliveryDate ? formatDateForTally(record.DeliveryDate) : ''}</UDF:TRANSPORTDELDATE>
      </UDF:TRANSPORTDELDATE.LIST>
      <UDF:EWAYBILLFLD.LIST DESC="'EwayBillFld'" ISLIST="YES" TYPE="String" INDEX="9865">
       <UDF:EWAYBILLFLD DESC="'EwayBillFld'">${record.EInv || ''}</UDF:EWAYBILLFLD>
      </UDF:EWAYBILLFLD.LIST>
      <UDF:PONUMBERFLD.LIST DESC="'PONumberFld'" ISLIST="YES" TYPE="String" INDEX="9867">
       <UDF:PONUMBERFLD DESC="'PONumberFld'">${record.PoNumber || ''}</UDF:PONUMBERFLD>
      </UDF:PONUMBERFLD.LIST>
      <UDF:TRACKINGNUMBER.LIST DESC="'Tracking Number'" ISLIST="YES" TYPE="String" INDEX="9868">
       <UDF:TRACKINGNUMBER DESC="'Tracking Number'">${record.TripId || ''}</UDF:TRACKINGNUMBER>
      </UDF:TRACKINGNUMBER.LIST>
      <UDF:TRASNPORTINVVALUE.LIST DESC="'TrasnportInvValue'" ISLIST="YES" TYPE="Amount" INDEX="4178">
       <UDF:TRASNPORTINVVALUE DESC="'TrasnportInvValue'">${record.InvValue || '0.00'}</UDF:TRASNPORTINVVALUE>
      </UDF:TRASNPORTINVVALUE.LIST>
      <UDF:TRSDELFIELD.LIST DESC="'TrsDelField'" ISLIST="YES" TYPE="String" INDEX="4168">
       <UDF:TRSDELFIELD DESC="'TrsDelField'">${record.DeliveryFromSpecial || ''}</UDF:TRSDELFIELD>
      </UDF:TRSDELFIELD.LIST>
     </STOCKITEM>
    </TALLYMESSAGE>
   </REQUESTDATA>
  </IMPORTDATA>
 </BODY>
</ENVELOPE>`;

                try {
                    // Uncomment this when ready to connect to Tally
                    const response = await axios.post('http://localhost:12000', tallyRequestXML, {
                        headers: { 'Content-Type': 'text/xml' }
                    });

                    if (response.status === 200) {
                        // Parse the Tally response
                        const parsedResponse = parseTallyResponse(response.data);
                        
                        // Update the record as synced
                        await query(
                            'UPDATE gc_creation SET send_to_tally = ? WHERE Id = ?',
                            ['yes', record.Id]
                        );
                        
                        results.push({
                            id: record.Id,
                            gcNumber: record.GcNumber,
                            status: 'synced',
                            message: 'Successfully synced with Tally',
                            tallyResponse: parsedResponse
                        });
                    } else {
                        throw new Error(`Tally returned status code ${response.status}`);
                    }
                } catch (error) {
                    console.error(`Error syncing GC ${record.GcNumber} with Tally:`, error);
                    results.push({
                        id: record.Id,
                        gcNumber: record.GcNumber,
                        status: 'error',
                        error: error.message,
                        tallyRequest: tallyRequestXML // Include the request for debugging
                    });
                }

            } catch (error) {
                console.error(`Error processing GC ${record.GcNumber}:`, error);
                results.push({
                    id: record.Id,
                    gcNumber: record.GcNumber,
                    status: 'error',
                    error: error.message
                });
            }
        }

        // Count successful and failed operations
        const successCount = results.filter(r => r.status === 'synced').length;
        const errorCount = results.filter(r => r.status === 'error').length;

        res.status(200).json({
            success: true,
            message: `Processed ${pendingRecords.length} records (${successCount} synced, ${errorCount} errors)`,
            data: results
        });

    } catch (error) {
        console.error('Error in push-to-tally endpoint:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to process Tally sync',
            error: error.message
        });
    }
});

router.put('/updateFreightCharges', (req, res) => {
    const updates = req.body.updates; 
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    if (!Array.isArray(updates) || updates.length === 0) {
        return res.status(400).json({ error: 'Must select 1 check Box' });
    }

    // First validate that all GCs belong to the specified company
    const gcIds = updates.map(update => update.Id).filter(id => id);
    if (gcIds.length === 0) {
        return res.status(400).json({ error: 'No valid GC IDs provided' });
    }

    // Check if all GCs belong to the company
    let validationQuery = 'SELECT Id FROM gc_creation WHERE CompanyId = ? AND Id IN (?)';
    let validationParams = [companyId, gcIds];

    if (branchId) {
        validationQuery += ' AND branch_id = ?';
        validationParams.push(branchId);
    }

    db.query(validationQuery, validationParams, (validationErr, validationResults) => {
        if (validationErr) {
            console.error('Validation error:', validationErr);
            return res.status(500).json({ error: 'Database validation error' });
        }

        if (validationResults.length !== gcIds.length) {
            return res.status(403).json({ 
                error: 'Access denied. Some GCs do not belong to this company or branch.',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            });
        }

        // Proceed with the update
        let sql = "UPDATE gc_creation SET FreightCharge = CASE Id";
        let receiptSql = ", ReceiptBillNo = CASE Id";
        let dateSql = ", ReceiptBillNoDate = CASE Id";
        let amountSql = ", ReceiptBillNoAmount = CASE Id";
        const endSql = " END WHERE Id IN (?)";

        let casesFreight = '';
        let casesReceipt = '';
        let casesDate = '';
        let casesAmount = '';
        let Id = [];

        updates.forEach(update => {
            if (update.Id && update.FreightCharge != null && update.ReceiptBillNo != null && update.ReceiptBillNoDate != null && update.ReceiptBillNoAmount != null) {
                casesFreight += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.FreightCharge)}`;
                casesReceipt += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.ReceiptBillNo)}`;
                casesDate += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.ReceiptBillNoDate)}`;
                casesAmount += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.ReceiptBillNoAmount)}`;
                Id.push(update.Id);
            }
        });

        if (Id.length === 0) {
            return res.status(400).json({ error: 'No valid updates provided' });
        }

        sql += casesFreight + " END" + receiptSql + casesReceipt + " END" + dateSql + casesDate + " END" + amountSql + casesAmount + endSql;

        db.query(sql, [Id], (err, result) => {
            if (err) {
                return res.status(500).json({ error: err });
            }
            return res.status(200).json({ 
                message: 'FreightCharges, ReceiptBillNos, ReceiptBillNoDates, and ReceiptBillNoAmounts updated successfully',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null,
                updatedRecords: result.affectedRows
            });
        });
    });
});


router.put('/challanNumber', (req, res) => {
    const updates = req.body.updates; 
    const companyId = req.query.companyId;
    const branchId = req.query.branchId; // Optional

    if (!companyId) {
        return res.status(400).json({ error: 'companyId is required' });
    }

    if (!Array.isArray(updates) || updates.length === 0) {
        return res.status(400).json({ error: 'Must select 1 check Box' });
    }

    // First validate that all GCs belong to the specified company
    const gcIds = updates.map(update => update.Id).filter(id => id);
    if (gcIds.length === 0) {
        return res.status(400).json({ error: 'No valid GC IDs provided' });
    }

    // Check if all GCs belong to the company
    let validationQuery = 'SELECT Id FROM gc_creation WHERE CompanyId = ? AND Id IN (?)';
    let validationParams = [companyId, gcIds];

    if (branchId) {
        validationQuery += ' AND branch_id = ?';
        validationParams.push(branchId);
    }

    db.query(validationQuery, validationParams, (validationErr, validationResults) => {
        if (validationErr) {
            console.error('Validation error:', validationErr);
            return res.status(500).json({ error: 'Database validation error' });
        }

        if (validationResults.length !== gcIds.length) {
            return res.status(403).json({ 
                error: 'Access denied. Some GCs do not belong to this company or branch.',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null
            });
        }

        // Proceed with the update
        let sql = "UPDATE gc_creation SET FreightCharge = CASE Id";
        let receiptSql = ", LcNo = CASE Id";
        let dateSql = ", ChallanBillNoDate = CASE Id";
        let amountSql = ", ChallanBillAmount = CASE Id";
        const endSql = " END WHERE Id IN (?)";

        let casesFreight = '';
        let casesReceipt = '';
        let casesDate = '';
        let casesAmount = '';
        let Id = [];

        updates.forEach(update => {
            if (update.Id && update.FreightCharge != null && update.LcNo != null && update.ReceiptBillNoDate != null && update.ReceiptBillNoAmount != null) {
                casesFreight += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.FreightCharge)}`;
                casesReceipt += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.LcNo)}`;
                casesDate += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.ReceiptBillNoDate)}`;
                casesAmount += ` WHEN ${db.escape(update.Id)} THEN ${db.escape(update.ReceiptBillNoAmount)}`;
                Id.push(update.Id);
            }
        });

        if (Id.length === 0) {
            return res.status(400).json({ error: 'No valid updates provided' });
        }

        sql += casesFreight + " END" + receiptSql + casesReceipt + " END" + dateSql + casesDate + " END" + amountSql + casesAmount + endSql;

        db.query(sql, [Id], (err, result) => {
            if (err) {
                return res.status(500).json({ error: err });
            }
            return res.status(200).json({ 
                message: 'FreightCharges, ReceiptBillNos, ReceiptBillNoDates, and ReceiptBillNoAmounts updated successfully',
                companyId: parseInt(companyId, 10),
                branchId: branchId ? parseInt(branchId, 10) : null,
                updatedRecords: result.affectedRows
            });
        });
    });
});


router.use(bodyParser.text({ type: 'application/xml' }));

router.post('/tallydata', async (req, res) => {
    const xmlData = req.body;  // Capture the XML sent from the frontend
    //console.log("xmlData",xmlData);
    
    try {
      // Forward the XML data to Tally
      const tallyResponse = await axios.post('http://localhost:12000', xmlData, {
        headers: {
          'Content-Type': 'application/xml',
        },
      });
  
      // Send response back to the frontend
      res.status(200).json({ message: 'Data sent to Tally successfully', data: tallyResponse.data });
    } catch (error) {
      // Handle errors
      res.status(500).json({ error: 'Failed to send data to Tally', details: error.message });
    }
  });

module.exports = router;