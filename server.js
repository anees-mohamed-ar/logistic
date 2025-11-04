const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const location = require('./location');
const consignor = require('./consignor');
const consignee = require('./consignee');
const broker = require('./broker');
const driver = require('./driver');
const truck_master = require('./truck_master');
const gc = require('./gc');
const profile = require('./profile');
const customer = require('./customer');
const company = require('./company');
const billing = require('./billing');
const supplier = require('./supplier');
const gst = require('./gst');
const bank = require('./bank');
const state = require('./state');
const receipt = require('./receipt');
const payment = require('./payment');
const otherpayment = require('./otherpayment');
const expensive = require('./expensive');
const km = require('./km');
const weight_to_rate = require('./weight_to_rate');
const temporary_gc = require('./temporary_gc');
const branch = require('./branch');


// Import GC management routes
const gcManagementRoutes = require('./routes/gcRoutes');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit per file
  },
  fileFilter: (req, file, cb) => {
    // Accept all file types
    cb(null, true);
  }
});

const app=express()
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Configure CORS
const corsOptions = {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

// Handle preflight requests
app.options('*', cors(corsOptions));

// Your existing routes
app.use('/billing', billing);
app.use('/location', location);
app.use('/consignor', consignor);
app.use('/consignee', consignee);
app.use('/broker', broker);
app.use('/driver', driver);
app.use('/truckmaster', truck_master);
app.use('/profile', profile);
app.use('/gc', gc);  // Your existing GC routes
app.use('/customer', customer);
app.use('/company', company);
app.use('/gst', gst);
app.use('/bank', bank);
app.use('/supplier', supplier);
app.use('/state', state);
app.use('/receipt', receipt);
app.use('/payment', payment);
app.use('/otherpayment', otherpayment);
app.use('/expensive', expensive);
app.use('/km', km);
app.use('/weight_to_rate', weight_to_rate);
app.use('/temporary-gc', temporary_gc);
app.use('/branch', branch);
// GC Management routes (new endpoints) - No authentication
app.use('/gc-management', gcManagementRoutes);

app.listen(8080,()=>{
    console.log('listening : 8080');
})