const express = require('express');
const db = require('./db');
const router = express.Router();
const axios = require('axios');
const multer = require('multer');
const path = require('path');

// Multer storage configuration for truck attachments
const truckUploadStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/truck_attachments/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, 'truck-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const truckUpload = multer({ storage: truckUploadStorage });

function formatDate(dateStr) {
    const date = new Date(dateStr);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0'); // Months are zero-based
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}${month}${day}`;
}
// Add new truck details (supports attachments via multipart/form-data)
router.post('/add', truckUpload.array('attachments', 10), (req, res) => {
    const {
        ownerName,
        ownerAddress,
        ownerMobileNumber,
        ownerEmail,
        ownerPanNumber,
        vechileNumber,
        typeofVechile,
        lorryWeight,
        unladenWeight,
        overWeight,
        engineeNumber,
        chaseNumber,
        roadTaxNumber,
        roadTaxExpDate,
        bankName,
        branchName,
        accountNumber,
        accountHolderName,
        ifscCode,
        micrCode,
        branchCode,
        insurance,
        insuranceExpDate,
        fcDate,
        CompanyId
    } = req.body;

    // Process uploaded attachments (if any)
    let attachmentFiles = [];
    const attachmentFileArray = req.files && Array.isArray(req.files) ? req.files : [];
    if (attachmentFileArray && attachmentFileArray.length > 0) {
        attachmentFiles = attachmentFileArray.map((file) => ({
            filename: file.filename,
            originalName: file.originalname,
            mimeType: file.mimetype,
            size: file.size,
            uploadDate: new Date().toISOString()
        }));
    }

    db.query(
        `INSERT INTO truckmaster (
            ownerName, ownerAddress, ownerMobileNumber, ownerEmail, ownerPanNumber,
            vechileNumber, typeofVechile, lorryWeight, unladenWeight, overWeight, engineeNumber,
            chaseNumber, roadTaxNumber, roadTaxExpDate, bankName, branchName, accountNumber, accountHolderName,
            ifscCode, micrCode, branchCode, insurance, insuranceExpDate, fcDate, CompanyId,
            attachment_files, attachment_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
            ownerName,
            ownerAddress,
            ownerMobileNumber,
            ownerEmail,
            ownerPanNumber,
            vechileNumber,
            typeofVechile,
            lorryWeight,
            unladenWeight,
            overWeight,
            engineeNumber,
            chaseNumber,
            roadTaxNumber,
            roadTaxExpDate,
            bankName,
            branchName,
            accountNumber,
            accountHolderName,
            ifscCode,
            micrCode,
            branchCode,
            insurance,
            insuranceExpDate,
            fcDate,
            CompanyId,
            attachmentFiles.length > 0 ? JSON.stringify(attachmentFiles) : null,
            attachmentFiles.length
        ], async (err, result) => {
            if (err) {
                console.error("Error inserting truck master record:", err);
                return res.status(500).json({ error: "Failed to add truck master" });
            }

            return res.status(200).json({
                message: "Truck master added successfully",
                id: result.insertId,
                attachments: attachmentFiles,
                attachmentCount: attachmentFiles.length
            });

        }
    );
});

        

                // Construct Tally request XML
//                 const tallyRequestXML = `
//              <ENVELOPE>
//  <HEADER>
//   <TALLYREQUEST>Import Data</TALLYREQUEST>
//  </HEADER>
//  <BODY>
//   <IMPORTDATA>
//    <REQUESTDESC>
//     <REPORTNAME>All Masters</REPORTNAME>
//     <STATICVARIABLES>
//      <SVCURRENTCOMPANY>Globe Transport Corporation HO</SVCURRENTCOMPANY>
//     </STATICVARIABLES>
//    </REQUESTDESC>
//    <REQUESTDATA>
//     <TALLYMESSAGE xmlns:UDF="TallyUDF">
//      <COSTCATEGORY NAME="Lorry" RESERVEDNAME="">
//       <LANGUAGENAME.LIST>
//        <NAME.LIST TYPE="String">
//         <NAME>Lorry</NAME>
//        </NAME.LIST>
//        <LANGUAGEID> 1033</LANGUAGEID>
//       </LANGUAGENAME.LIST>
//      </COSTCATEGORY>
//     </TALLYMESSAGE>
//     <TALLYMESSAGE xmlns:UDF="TallyUDF">
//      <COSTCENTRE NAME="${vechileNumber}" RESERVEDNAME="">
//       <PARENT>Lorry</PARENT>
//       <CATEGORY>Primary Cost Category</CATEGORY>
//       <ASORIGINAL>Yes</ASORIGINAL>
//       <LANGUAGENAME.LIST>
//        <NAME.LIST TYPE="String">
//         <NAME>${vechileNumber}</NAME>
//        </NAME.LIST>
//        <LANGUAGEID> 1033</LANGUAGEID>
//       </LANGUAGENAME.LIST>

//   <UDF:LORRYWGT.LIST DESC="LorryWgt" ISLIST="YES" TYPE="Number" INDEX="8818">
//        <UDF:LORRYWGT DESC="LorryWgt"> ${lorryWeight}</UDF:LORRYWGT>
//       </UDF:LORRYWGT.LIST>
//       <UDF:LORRYUNLDWGT.LIST DESC="LorryUnldWgt" ISLIST="YES" TYPE="Number" INDEX="8819">
//        <UDF:LORRYUNLDWGT DESC="LorryUnldWgt"> ${unladenWeight}</UDF:LORRYUNLDWGT>
//       </UDF:LORRYUNLDWGT.LIST>
//       <UDF:LORRYOVWGT.LIST DESC="LorryOvWgt" ISLIST="YES" TYPE="Number" INDEX="8820">
//        <UDF:LORRYOVWGT DESC="LorryOvWgt"> ${overWeight}</UDF:LORRYOVWGT>
//       </UDF:LORRYOVWGT.LIST>
//       <UDF:LORRYROTAXEXP.LIST DESC="LorryRoTaxExp" ISLIST="YES" TYPE="Date" INDEX="8824">
//        <UDF:LORRYROTAXEXP DESC="LorryRoTaxExp">${roadTaxExpDate}</UDF:LORRYROTAXEXP>
//       </UDF:LORRYROTAXEXP.LIST>
//       <UDF:ELITEINSNUMBER.LIST DESC="EliteinsNumber" ISLIST="YES" TYPE="String" INDEX="3135">
//        <UDF:ELITEINSNUMBER DESC="EliteinsNumber"></UDF:ELITEINSNUMBER>
//       </UDF:ELITEINSNUMBER.LIST>
//       <UDF:SANJAYOWNERNAME.LIST DESC="SanjayOwnerName" ISLIST="YES" TYPE="String" INDEX="4111">
//        <UDF:SANJAYOWNERNAME DESC="SanjayOwnerName">${ownerName}</UDF:SANJAYOWNERNAME>
//       </UDF:SANJAYOWNERNAME.LIST>
//       <UDF:SANJAYOWNERADDRESS.LIST DESC="SanjayOwnerAddress" ISLIST="YES" TYPE="String" INDEX="4112">
//        <UDF:SANJAYOWNERADDRESS DESC="SanjayOwnerAddress">${ownerAddress}</UDF:SANJAYOWNERADDRESS>
//       </UDF:SANJAYOWNERADDRESS.LIST>
//       <UDF:SANJAYPANNONAME.LIST DESC="SanjayPanNoName" ISLIST="YES" TYPE="String" INDEX="4113">
//        <UDF:SANJAYPANNONAME DESC="SanjayPanNoName">${ownerPanNumber}</UDF:SANJAYPANNONAME>
//       </UDF:SANJAYPANNONAME.LIST>
//       <UDF:SANJAYPHONENONAME.LIST DESC="SanjayPhoneNoName" ISLIST="YES" TYPE="String" INDEX="4114">
//        <UDF:SANJAYPHONENONAME DESC="SanjayPhoneNoName">${ownerMobileNumber}</UDF:SANJAYPHONENONAME>
//       </UDF:SANJAYPHONENONAME.LIST>
//       <UDF:SANJAYFAXNONAME.LIST DESC="SanjayFaxNoName" ISLIST="YES" TYPE="String" INDEX="4115">
//        <UDF:SANJAYFAXNONAME DESC="SanjayFaxNoName"></UDF:SANJAYFAXNONAME>
//       </UDF:SANJAYFAXNONAME.LIST>
//       <UDF:SANJAYMOBILENONAME.LIST DESC="SanjayMobileNoName" ISLIST="YES" TYPE="String" INDEX="4116">
//        <UDF:SANJAYMOBILENONAME DESC="SanjayMobileNoName">${ownerMobileNumber}</UDF:SANJAYMOBILENONAME>
//       </UDF:SANJAYMOBILENONAME.LIST>
//       <UDF:TYPEOFVEHICLE.LIST DESC="TypeOfVehicle" ISLIST="YES" TYPE="String" INDEX="5890">
//        <UDF:TYPEOFVEHICLE DESC="TypeOfVehicle">${typeofVechile}</UDF:TYPEOFVEHICLE>
//       </UDF:TYPEOFVEHICLE.LIST>
//       <UDF:LORRYENGNO.LIST DESC="LorryEngNo" ISLIST="YES" TYPE="String" INDEX="8821">
//        <UDF:LORRYENGNO DESC="LorryEngNo">${engineeNumber}</UDF:LORRYENGNO>
//       </UDF:LORRYENGNO.LIST>
//       <UDF:LORRYCHASENO.LIST DESC="LorryChaseNo" ISLIST="YES" TYPE="String" INDEX="8822">
//        <UDF:LORRYCHASENO DESC="LorryChaseNo">${chaseNumber}</UDF:LORRYCHASENO>
//       </UDF:LORRYCHASENO.LIST>
//       <UDF:LORRYROTAX.LIST DESC="LorryRoTax" ISLIST="YES" TYPE="String" INDEX="8823">
//        <UDF:LORRYROTAX DESC="LorryRoTax">${roadTaxNumber}</UDF:LORRYROTAX>
//       </UDF:LORRYROTAX.LIST>
//       <UDF:LORRYACBKNA.LIST DESC="LorryAcBkNa" ISLIST="YES" TYPE="String" INDEX="8825">
//        <UDF:LORRYACBKNA DESC="LorryAcBkNa">${bankName}</UDF:LORRYACBKNA>
//       </UDF:LORRYACBKNA.LIST>
//       <UDF:LORRYACNAME.LIST DESC="LorryAcName" ISLIST="YES" TYPE="String" INDEX="8826">
//        <UDF:LORRYACNAME DESC="LorryAcName">${accountHolderName}</UDF:LORRYACNAME>
//       </UDF:LORRYACNAME.LIST>
//       <UDF:LORRYACNO.LIST DESC="LorryAcNo" ISLIST="YES" TYPE="String" INDEX="8827">
//        <UDF:LORRYACNO DESC="LorryAcNo">${accountNumber}</UDF:LORRYACNO>
//       </UDF:LORRYACNO.LIST>
//       <UDF:LORRYACBRANCH.LIST DESC="LorryAcBranch" ISLIST="YES" TYPE="String" INDEX="8828">
//        <UDF:LORRYACBRANCH DESC="LorryAcBranch">${branchName}</UDF:LORRYACBRANCH>
//       </UDF:LORRYACBRANCH.LIST>
//       <UDF:LORRYACIFSC.LIST DESC="LorryAcIfsc" ISLIST="YES" TYPE="String" INDEX="8829">
//        <UDF:LORRYACIFSC DESC="LorryAcIfsc">${ifscCode}</UDF:LORRYACIFSC>
//       </UDF:LORRYACIFSC.LIST>
//       <UDF:LORRYOWNEREMAIL.LIST DESC="LorryOwnerEmail" ISLIST="YES" TYPE="String" INDEX="8830">
//        <UDF:LORRYOWNEREMAIL DESC="LorryOwnerEmail">${ownerEmail}</UDF:LORRYOWNEREMAIL>
//       </UDF:LORRYOWNEREMAIL.LIST>
//      </COSTCENTRE>
//     </TALLYMESSAGE>
//    </REQUESTDATA>
//   </IMPORTDATA>
//  </BODY>
// </ENVELOPE>
//                 `;
// console.log(tallyRequestXML);

//                 try {
//                     const response = await axios.post('http://localhost:12000', tallyRequestXML, {
//                         headers: { 'Content-Type': 'text/xml' }
//                     });

//                     if (response.status === 200) {
//                         console.log(response);
//                         res.status(200).json({ message: "Truck master data and Tally entry added successfully" });
//                     } else {
//                         res.status(500).json({ error: "Failed to add Tally entry" });
//                     }
//                 } catch (tallyError) {
//                     console.error("Tally request error:", tallyError);
//                     res.status(500).json({ error: "Failed to add Tally entry" });
//                 }
     





// Update truck details
router.put('/update/:vechileNumber', truckUpload.array('attachments', 10), (req, res) => {
    const oldVechileNumber = req.params.vechileNumber; // Get the old vehicle number from URL params
    const {
        ownerName,
        ownerAddress,
        ownerMobileNumber,
        ownerEmail,
        ownerPanNumber,
        vechileNumber, // New vehicle number from the request body
        typeofVechile,
        lorryWeight,
        unladenWeight,
        overWeight,
        engineeNumber,
        chaseNumber,
        roadTaxNumber,
        roadTaxExpDate,
        bankName,
        branchName,
        accountNumber,
        accountHolderName,
        ifscCode,
        micrCode,
        branchCode,
        insurance,
        insuranceExpDate,
        fcDate
    } = req.body;

    // Check if the new vehicle number is different from the existing one
    if (vechileNumber !== oldVechileNumber) {
        // Check if the new vehicle number already exists
        db.query(
            `SELECT * FROM truckmaster WHERE vechileNumber = ?`,
            [vechileNumber],
            (err, result) => {
                if (err) {
                    return res.status(500).send(err);
                }
                if (result.length > 0) {
                    return res.status(400).json({ error: 'Vehicle number already exists' });
                }
                // Proceed with the update if the new vehicle number does not exist
                performUpdate();
            }
        );
    } else {
        // If the vehicle number is not changing, directly perform the update
        performUpdate();
    }

    // Function to perform the update
    function performUpdate() {
        // Process new uploaded attachments (if any)
        let newAttachmentFiles = [];
        const attachmentFileArray = req.files && Array.isArray(req.files) ? req.files : [];
        if (attachmentFileArray && attachmentFileArray.length > 0) {
            newAttachmentFiles = attachmentFileArray.map((file) => ({
                filename: file.filename,
                originalName: file.originalname,
                mimeType: file.mimetype,
                size: file.size,
                uploadDate: new Date().toISOString()
            }));
        }

        // First fetch existing attachments so we can append
        const fetchSql = 'SELECT attachment_files FROM truckmaster WHERE vechileNumber = ?';
        db.query(fetchSql, [oldVechileNumber], (fetchErr, fetchResult) => {
            if (fetchErr) {
                console.error('Error fetching existing truck attachments:', fetchErr);
            }

            let existingAttachments = [];
            if (!fetchErr && fetchResult && fetchResult.length > 0 && fetchResult[0].attachment_files) {
                try {
                    existingAttachments = JSON.parse(fetchResult[0].attachment_files) || [];
                } catch (e) {
                    console.error('Error parsing existing truck attachments JSON:', e);
                    existingAttachments = [];
                }
            }

            const combinedAttachments = [...existingAttachments, ...newAttachmentFiles];

            db.query(
                `UPDATE truckmaster SET ownerName=?, ownerAddress=?, ownerMobileNumber=?, ownerEmail=?, ownerPanNumber=?, 
                vechileNumber=?, typeofVechile=?, lorryWeight=?, unladenWeight=?, overWeight=?, engineeNumber=?, 
                chaseNumber=?, roadTaxNumber=?, roadTaxExpDate=?, bankName=?, branchName=?, accountNumber=?, 
                accountHolderName=?, ifscCode=?, micrCode=?, branchCode=?, insurance=?, insuranceExpDate=?, 
                fcDate=?, attachment_files = ?, attachment_count = ? WHERE vechileNumber=?`,
                [
                    ownerName,
                    ownerAddress,
                    ownerMobileNumber,
                    ownerEmail,
                    ownerPanNumber,
                    vechileNumber, // Updated vehicle number
                    typeofVechile,
                    lorryWeight,
                    unladenWeight,
                    overWeight,
                    engineeNumber,
                    chaseNumber,
                    roadTaxNumber,
                    roadTaxExpDate,
                    bankName,
                    branchName,
                    accountNumber,
                    accountHolderName,
                    ifscCode,
                    micrCode,
                    branchCode,
                    insurance,
                    insuranceExpDate,
                    fcDate,
                    combinedAttachments.length > 0 ? JSON.stringify(combinedAttachments) : null,
                    combinedAttachments.length,
                    oldVechileNumber // Where clause based on the old vehicle number
                ],
                async (err, result) => {
                    if (err) {
                        console.error("Error updating truck master record:", err);
                        return res.status(500).json({ error: "Failed to update truck master" });
                    }

                    return res.status(200).json({
                        message: "Truck master updated successfully",
                        attachments: combinedAttachments,
                        attachmentCount: combinedAttachments.length
                    });

                }
            );
        });
    }
});



                // Construct Tally request XML for update
//                 const tallyRequestXML = `
//              <ENVELOPE>
//  <HEADER>
//   <TALLYREQUEST>Import Data</TALLYREQUEST>
//  </HEADER>
//  <BODY>
//   <IMPORTDATA>
//    <REQUESTDESC>
//     <REPORTNAME>All Masters</REPORTNAME>
//     <STATICVARIABLES>
//      <SVCURRENTCOMPANY>Globe Transport Corporation HO</SVCURRENTCOMPANY>
//     </STATICVARIABLES>
//    </REQUESTDESC>
//    <REQUESTDATA>
//     <TALLYMESSAGE xmlns:UDF="TallyUDF">
//      <COSTCENTRE NAME="${vechileNumber}" RESERVEDNAME="">
//       <PARENT>Lorry</PARENT>
//       <CATEGORY>Primary Cost Category</CATEGORY>
//       <ASORIGINAL>Yes</ASORIGINAL>
//       <LANGUAGENAME.LIST>
//        <NAME.LIST TYPE="String">
//         <NAME>${vechileNumber}</NAME>
//        </NAME.LIST>
//        <LANGUAGEID> 1033</LANGUAGEID>
//       </LANGUAGENAME.LIST>

//   <UDF:LORRYWGT.LIST DESC="LorryWgt" ISLIST="YES" TYPE="Number" INDEX="8818">
//        <UDF:LORRYWGT DESC="LorryWgt"> ${lorryWeight}</UDF:LORRYWGT>
//       </UDF:LORRYWGT.LIST>
//       <UDF:LORRYUNLDWGT.LIST DESC="LorryUnldWgt" ISLIST="YES" TYPE="Number" INDEX="8819">
//        <UDF:LORRYUNLDWGT DESC="LorryUnldWgt"> ${unladenWeight}</UDF:LORRYUNLDWGT>
//       </UDF:LORRYUNLDWGT.LIST>
//       <UDF:LORRYOVWGT.LIST DESC="LorryOvWgt" ISLIST="YES" TYPE="Number" INDEX="8820">
//        <UDF:LORRYOVWGT DESC="LorryOvWgt"> ${overWeight}</UDF:LORRYOVWGT>
//       </UDF:LORRYOVWGT.LIST>
//       <UDF:LORRYROTAXEXP.LIST DESC="LorryRoTaxExp" ISLIST="YES" TYPE="Date" INDEX="8824">
//        <UDF:LORRYROTAXEXP DESC="LorryRoTaxExp">${roadTaxExpDate}</UDF:LORRYROTAXEXP>
//       </UDF:LORRYROTAXEXP.LIST>
//       <UDF:ELITEINSNUMBER.LIST DESC="EliteinsNumber" ISLIST="YES" TYPE="String" INDEX="3135">
//        <UDF:ELITEINSNUMBER DESC="EliteinsNumber"></UDF:ELITEINSNUMBER>
//       </UDF:ELITEINSNUMBER.LIST>
//       <UDF:SANJAYOWNERNAME.LIST DESC="SanjayOwnerName" ISLIST="YES" TYPE="String" INDEX="4111">
//        <UDF:SANJAYOWNERNAME DESC="SanjayOwnerName">${ownerName}</UDF:SANJAYOWNERNAME>
//       </UDF:SANJAYOWNERNAME.LIST>
//       <UDF:SANJAYOWNERADDRESS.LIST DESC="SanjayOwnerAddress" ISLIST="YES" TYPE="String" INDEX="4112">
//        <UDF:SANJAYOWNERADDRESS DESC="SanjayOwnerAddress">${ownerAddress}</UDF:SANJAYOWNERADDRESS>
//       </UDF:SANJAYOWNERADDRESS.LIST>
//       <UDF:SANJAYPANNONAME.LIST DESC="SanjayPanNoName" ISLIST="YES" TYPE="String" INDEX="4113">
//        <UDF:SANJAYPANNONAME DESC="SanjayPanNoName">${ownerPanNumber}</UDF:SANJAYPANNONAME>
//       </UDF:SANJAYPANNONAME.LIST>
//       <UDF:SANJAYPHONENONAME.LIST DESC="SanjayPhoneNoName" ISLIST="YES" TYPE="String" INDEX="4114">
//        <UDF:SANJAYPHONENONAME DESC="SanjayPhoneNoName">${ownerMobileNumber}</UDF:SANJAYPHONENONAME>
//       </UDF:SANJAYPHONENONAME.LIST>
//       <UDF:SANJAYFAXNONAME.LIST DESC="SanjayFaxNoName" ISLIST="YES" TYPE="String" INDEX="4115">
//        <UDF:SANJAYFAXNONAME DESC="SanjayFaxNoName"></UDF:SANJAYFAXNONAME>
//       </UDF:SANJAYFAXNONAME.LIST>
//       <UDF:SANJAYMOBILENONAME.LIST DESC="SanjayMobileNoName" ISLIST="YES" TYPE="String" INDEX="4116">
//        <UDF:SANJAYMOBILENONAME DESC="SanjayMobileNoName">${ownerMobileNumber}</UDF:SANJAYMOBILENONAME>
//       </UDF:SANJAYMOBILENONAME.LIST>
//       <UDF:TYPEOFVEHICLE.LIST DESC="TypeOfVehicle" ISLIST="YES" TYPE="String" INDEX="5890">
//        <UDF:TYPEOFVEHICLE DESC="TypeOfVehicle">${typeofVechile}</UDF:TYPEOFVEHICLE>
//       </UDF:TYPEOFVEHICLE.LIST>
//       <UDF:LORRYENGNO.LIST DESC="LorryEngNo" ISLIST="YES" TYPE="String" INDEX="8821">
//        <UDF:LORRYENGNO DESC="LorryEngNo">${engineeNumber}</UDF:LORRYENGNO>
//       </UDF:LORRYENGNO.LIST>
//       <UDF:LORRYCHASENO.LIST DESC="LorryChaseNo" ISLIST="YES" TYPE="String" INDEX="8822">
//        <UDF:LORRYCHASENO DESC="LorryChaseNo">${chaseNumber}</UDF:LORRYCHASENO>
//       </UDF:LORRYCHASENO.LIST>
//       <UDF:LORRYROTAX.LIST DESC="LorryRoTax" ISLIST="YES" TYPE="String" INDEX="8823">
//        <UDF:LORRYROTAX DESC="LorryRoTax">${roadTaxNumber}</UDF:LORRYROTAX>
//       </UDF:LORRYROTAX.LIST>
//       <UDF:LORRYACBKNA.LIST DESC="LorryAcBkNa" ISLIST="YES" TYPE="String" INDEX="8825">
//        <UDF:LORRYACBKNA DESC="LorryAcBkNa">${bankName}</UDF:LORRYACBKNA>
//       </UDF:LORRYACBKNA.LIST>
//       <UDF:LORRYACNAME.LIST DESC="LorryAcName" ISLIST="YES" TYPE="String" INDEX="8826">
//        <UDF:LORRYACNAME DESC="LorryAcName">${accountHolderName}</UDF:LORRYACNAME>
//       </UDF:LORRYACNAME.LIST>
//       <UDF:LORRYACNO.LIST DESC="LorryAcNo" ISLIST="YES" TYPE="String" INDEX="8827">
//        <UDF:LORRYACNO DESC="LorryAcNo">${accountNumber}</UDF:LORRYACNO>
//       </UDF:LORRYACNO.LIST>
//       <UDF:LORRYACBRANCH.LIST DESC="LorryAcBranch" ISLIST="YES" TYPE="String" INDEX="8828">
//        <UDF:LORRYACBRANCH DESC="LorryAcBranch">${branchName}</UDF:LORRYACBRANCH>
//       </UDF:LORRYACBRANCH.LIST>
//       <UDF:LORRYACIFSC.LIST DESC="LorryAcIfsc" ISLIST="YES" TYPE="String" INDEX="8829">
//        <UDF:LORRYACIFSC DESC="LorryAcIfsc">${ifscCode}</UDF:LORRYACIFSC>
//       </UDF:LORRYACIFSC.LIST>
//       <UDF:LORRYOWNEREMAIL.LIST DESC="LorryOwnerEmail" ISLIST="YES" TYPE="String" INDEX="8830">
//        <UDF:LORRYOWNEREMAIL DESC="LorryOwnerEmail">${ownerEmail}</UDF:LORRYOWNEREMAIL>
//       </UDF:LORRYOWNEREMAIL.LIST>
//      </COSTCENTRE>
//     </TALLYMESSAGE>
//    </REQUESTDATA>
//   </IMPORTDATA>
//  </BODY>
// </ENVELOPE>
//                 `;
// console.log(tallyRequestXML);

//                 try {
//                     const response = await axios.post('http://localhost:12000', tallyRequestXML, {
//                         headers: { 'Content-Type': 'text/xml' }
//                     });

//                     if (response.status === 200) {
//                         console.log(response);
//                         res.status(200).json({ message: "Truck details and Tally entry updated successfully" });
//                     } else {
//                         res.status(500).json({ error: "Failed to update Tally entry" });
//                     }
//                 } catch (tallyError) {
//                     console.error("Tally request error:", tallyError);
//                     res.status(500).json({ error: "Failed to update Tally entry" });
//                 }
//             }
//         );
//     }
// });


router.get('/search', (req, res) => {
    const sql = 'SELECT * FROM truckmaster';
    db.query(sql, (err, data) => {
        if (err) {
            return res.status(500).send(err);
        }
        return res.status(200).json(data);
    });
});

router.get('/search1', (req, res) => {
const sql = 'SELECT vechileNumber FROM truckmaster';
    db.query(sql, (err, data) => {
        if (err) {
            return res.status(500).send(err);
        }
        return res.status(200).json(data);
    });
});

router.get('/search/number', (req, res) => {
    const vechileNumber = req.query.vechileNumber; // Get vehicle number from query params
    if (!vechileNumber) {
        return res.status(400).json({ error: "Vehicle number is required" });
    }

    const sql = 'SELECT * FROM truckmaster WHERE vechileNumber = ?';
    db.query(sql, [vechileNumber], (err, data) => {
        if (err) {
            return res.status(500).send(err);
        }
        return res.status(200).json(data);
    });
});


module.exports = router;
