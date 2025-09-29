/*
SQLyog Community v12.4.0 (64 bit)
MySQL - 8.0.42 : Database - logistic
*********************************************************************
*/


/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`logistic` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `logistic`;

/*Table structure for table `bank` */

DROP TABLE IF EXISTS `bank`;

CREATE TABLE `bank` (
  `id` int NOT NULL AUTO_INCREMENT,
  `bankName` varchar(100) DEFAULT NULL,
  `branchName` varchar(1000) DEFAULT NULL,
  `accountNumber` varchar(100) DEFAULT NULL,
  `accountHolderName` varchar(100) DEFAULT NULL,
  `ifscCode` varchar(100) DEFAULT NULL,
  `micrCode` varchar(100) DEFAULT NULL,
  `branchCode` varchar(100) DEFAULT NULL,
  `bankDetails` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

/*Table structure for table `billing` */

DROP TABLE IF EXISTS `billing`;

CREATE TABLE `billing` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customerName` varchar(300) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `bankDetails` varchar(300) DEFAULT NULL,
  `billNo` varchar(100) DEFAULT NULL,
  `receiptNo` varchar(100) DEFAULT NULL,
  `cgstPercentage` varchar(100) DEFAULT NULL,
  `sgstPercentage` varchar(100) DEFAULT NULL,
  `cgst` float DEFAULT NULL,
  `sgst` float DEFAULT NULL,
  `subTotal` float DEFAULT NULL,
  `openingAmount` float DEFAULT NULL,
  `receiptAmount` float NOT NULL,
  `pendingAmount` float DEFAULT NULL,
  `balanceAmount` float DEFAULT NULL,
  `total` float DEFAULT NULL,
  `haltingCharges` float DEFAULT NULL,
  `loadingCharges` float DEFAULT NULL,
  `unloadingCharges` float DEFAULT NULL,
  `otherCharges` float DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  `uploadedTime` time DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=latin1;

/*Table structure for table `broker` */

DROP TABLE IF EXISTS `broker`;

CREATE TABLE `broker` (
  `brokerId` int NOT NULL AUTO_INCREMENT,
  `brokerName` varchar(30) DEFAULT NULL,
  `brokerAddress` varchar(300) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `dateofBirth` varchar(100) DEFAULT NULL,
  `commissionPercentage` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `bloodGroup` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `mobileNumber` varchar(100) DEFAULT NULL,
  `panNumber` varchar(200) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `brokerId` (`brokerId`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=latin1;

/*Table structure for table `charge_details` */

DROP TABLE IF EXISTS `charge_details`;

CREATE TABLE `charge_details` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `charge_id` int NOT NULL,
  `reason` varchar(1000) DEFAULT NULL,
  `gc_number` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `CompanyId` varchar(1000) DEFAULT NULL,
  `date` varchar(500) DEFAULT NULL,
  `otherPaymentNumber` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

/*Table structure for table `charges` */

DROP TABLE IF EXISTS `charges`;

CREATE TABLE `charges` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `date` varchar(500) DEFAULT NULL,
  `other_payment_id` varchar(1000) NOT NULL,
  `value` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `remarks` varchar(1000) NOT NULL,
  `CompanyId` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

/*Table structure for table `company` */

DROP TABLE IF EXISTS `company`;

CREATE TABLE `company` (
  `id` int NOT NULL AUTO_INCREMENT,
  `companyName` varchar(300) DEFAULT NULL,
  `address` varchar(300) DEFAULT NULL,
  `phoneNumber` varchar(300) DEFAULT NULL,
  `email` varchar(300) DEFAULT NULL,
  `gst` varchar(300) DEFAULT NULL,
  `stateId` varchar(100) DEFAULT NULL,
  `state` varchar(300) DEFAULT NULL,
  `country` varchar(300) DEFAULT NULL,
  `mobile` varchar(300) DEFAULT NULL,
  `website` varchar(30000) DEFAULT NULL,
  `contactPerson` varchar(100) DEFAULT NULL,
  `finance` varchar(100) DEFAULT NULL,
  `jurisdiction` varchar(100) DEFAULT NULL,
  `companyLogo` mediumtext,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

/*Table structure for table `consignee` */

DROP TABLE IF EXISTS `consignee`;

CREATE TABLE `consignee` (
  `consigneeId` int NOT NULL AUTO_INCREMENT,
  `consigneeName` varchar(1000) DEFAULT NULL,
  `address` varchar(30000) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `contact` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `mobileNumber` varchar(100) DEFAULT NULL,
  `gst` varchar(100) DEFAULT NULL,
  `panNumber` varchar(100) DEFAULT NULL,
  `msmeNumber` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `cinNumber` varchar(100) DEFAULT NULL,
  `compType` varchar(100) DEFAULT NULL,
  `IndustrialType` varchar(100) DEFAULT NULL,
  `fax` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `consigneeId` (`consigneeId`)
) ENGINE=InnoDB AUTO_INCREMENT=388 DEFAULT CHARSET=latin1;

/*Table structure for table `consignor` */

DROP TABLE IF EXISTS `consignor`;

CREATE TABLE `consignor` (
  `consignorId` int NOT NULL AUTO_INCREMENT,
  `consignorName` varchar(300) DEFAULT NULL,
  `address` varchar(300) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `district` varchar(20) DEFAULT NULL,
  `contact` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `mobileNumber` varchar(100) DEFAULT NULL,
  `gst` varchar(100) DEFAULT NULL,
  `panNumber` varchar(100) DEFAULT NULL,
  `msmeNumber` varchar(30) DEFAULT NULL,
  `email` varchar(30) DEFAULT NULL,
  `cinNumber` varchar(100) DEFAULT NULL,
  `compType` varchar(100) DEFAULT NULL,
  `industrialType` varchar(30) DEFAULT NULL,
  `fax` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`consignorId`),
  KEY `consignorId` (`consignorId`)
) ENGINE=InnoDB AUTO_INCREMENT=10404 DEFAULT CHARSET=latin1;

/*Table structure for table `customername` */

DROP TABLE IF EXISTS `customername`;

CREATE TABLE `customername` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customerName` varchar(300) DEFAULT NULL,
  `address` varchar(300) DEFAULT NULL,
  `state` varchar(300) DEFAULT NULL,
  `location` varchar(300) DEFAULT NULL,
  `district` varchar(300) DEFAULT NULL,
  `contact` varchar(300) DEFAULT NULL,
  `phoneNumber` varchar(300) DEFAULT NULL,
  `MobileNumber` varchar(300) DEFAULT NULL,
  `gst` varchar(300) DEFAULT NULL,
  `panNumber` varchar(300) DEFAULT NULL,
  `msmeNumber` varchar(300) DEFAULT NULL,
  `email` varchar(300) DEFAULT NULL,
  `cinNumber` varchar(300) DEFAULT NULL,
  `compType` varchar(300) DEFAULT NULL,
  `IndustrialType` varchar(300) DEFAULT NULL,
  `fax` varchar(300) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  `branchName` varchar(100) DEFAULT NULL,
  `bankName` varchar(100) DEFAULT NULL,
  `ifscCode` varchar(100) DEFAULT NULL,
  `micrCode` varchar(100) DEFAULT NULL,
  `accountNumber` varchar(1000) DEFAULT NULL,
  `accountHolderName` varchar(1000) DEFAULT NULL,
  `branchCode` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;

/*Table structure for table `driver` */

DROP TABLE IF EXISTS `driver`;

CREATE TABLE `driver` (
  `driverId` int NOT NULL AUTO_INCREMENT,
  `driverName` varchar(300) DEFAULT NULL,
  `driverAddress` varchar(300) DEFAULT NULL,
  `district` varchar(300) DEFAULT NULL,
  `state` varchar(300) DEFAULT NULL,
  `country` varchar(300) DEFAULT NULL,
  `dateofBirth` varchar(300) DEFAULT NULL,
  `dlNumber` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `bloodGroup` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `mobileNumber` varchar(100) DEFAULT NULL,
  `panNumber` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `driverId` (`driverId`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

/*Table structure for table `expensive` */

DROP TABLE IF EXISTS `expensive`;

CREATE TABLE `expensive` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ledger` varchar(1000) DEFAULT NULL,
  `name` varchar(1000) DEFAULT NULL,
  `group` varchar(1000) DEFAULT NULL,
  `CompanyId` varchar(1000) DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

/*Table structure for table `gc_creation` */

DROP TABLE IF EXISTS `gc_creation`;

CREATE TABLE `gc_creation` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `BranchCode` varchar(300) DEFAULT NULL,
  `Branch` varchar(300) DEFAULT NULL,
  `GcNumber` varchar(300) DEFAULT NULL,
  `GcDate` varchar(300) DEFAULT NULL,
  `TruckNumber` varchar(300) DEFAULT NULL,
  `vechileNumber` varchar(300) DEFAULT NULL,
  `TruckType` varchar(300) DEFAULT NULL,
  `BrokerNameShow` varchar(300) DEFAULT NULL,
  `BrokerName` varchar(300) DEFAULT NULL,
  `TripId` varchar(300) DEFAULT NULL,
  `PoNumber` varchar(300) DEFAULT NULL,
  `TruckFrom` varchar(300) DEFAULT NULL,
  `TruckTo` varchar(300) DEFAULT NULL,
  `PaymentDetails` varchar(300) DEFAULT NULL,
  `LcNo` varchar(300) DEFAULT NULL,
  `DeliveryDate` varchar(300) DEFAULT NULL,
  `EBillDate` varchar(300) DEFAULT NULL,
  `EBillExpDate` varchar(300) DEFAULT NULL,
  `DriverNameShow` varchar(300) DEFAULT NULL,
  `DriverName` varchar(300) DEFAULT NULL,
  `DriverPhoneNumber` varchar(300) DEFAULT NULL,
  `Consignor` varchar(900) DEFAULT NULL,
  `ConsignorName` varchar(900) DEFAULT NULL,
  `ConsignorAddress` varchar(900) DEFAULT NULL,
  `ConsignorGst` varchar(900) DEFAULT NULL,
  `Consignee` varchar(900) DEFAULT NULL,
  `ConsigneeName` varchar(900) DEFAULT NULL,
  `ConsigneeAddress` varchar(900) DEFAULT NULL,
  `ConsigneeGst` varchar(900) DEFAULT NULL,
  `CustInvNo` varchar(300) DEFAULT NULL,
  `InvValue` varchar(300) DEFAULT NULL,
  `EInv` varchar(300) DEFAULT NULL,
  `EInvDate` varchar(300) DEFAULT NULL,
  `Eda` varchar(300) DEFAULT NULL,
  `NumberofPkg` varchar(300) DEFAULT NULL,
  `MethodofPkg` varchar(300) DEFAULT NULL,
  `TotalRate` varchar(1000) DEFAULT NULL,
  `TotalWeight` varchar(300) DEFAULT NULL,
  `Rate` varchar(300) DEFAULT NULL,
  `km` varchar(250) DEFAULT NULL,
  `km2` varchar(250) DEFAULT NULL,
  `km3` varchar(250) DEFAULT NULL,
  `km4` varchar(250) DEFAULT NULL,
  `ActualWeightKgs` varchar(300) DEFAULT NULL,
  `Total` varchar(300) DEFAULT NULL,
  `PrivateMark` varchar(300) DEFAULT NULL,
  `PrivateMark2` varchar(300) DEFAULT NULL,
  `PrivateMark3` varchar(300) DEFAULT NULL,
  `PrivateMark4` varchar(300) DEFAULT NULL,
  `Charges` varchar(300) DEFAULT NULL,
  `Charges2` varchar(300) DEFAULT NULL,
  `Charges3` varchar(300) DEFAULT NULL,
  `Charges4` varchar(300) DEFAULT NULL,
  `NumberofPkg2` varchar(300) DEFAULT NULL,
  `MethodofPkg2` varchar(300) DEFAULT NULL,
  `Rate2` varchar(300) DEFAULT NULL,
  `Total2` varchar(300) DEFAULT NULL,
  `ActualWeightKgs2` varchar(300) DEFAULT NULL,
  `NumberofPkg3` varchar(300) DEFAULT NULL,
  `MethodofPkg3` varchar(300) DEFAULT NULL,
  `Rate3` varchar(300) DEFAULT NULL,
  `Total3` varchar(300) DEFAULT NULL,
  `ActualWeightKgs3` varchar(300) DEFAULT NULL,
  `NumberofPkg4` varchar(300) DEFAULT NULL,
  `MethodofPkg4` varchar(300) DEFAULT NULL,
  `Rate4` varchar(300) DEFAULT NULL,
  `Total4` varchar(300) DEFAULT NULL,
  `ActualWeightKgs4` varchar(300) DEFAULT NULL,
  `GoodContain` varchar(900) DEFAULT NULL,
  `GoodContain2` varchar(900) DEFAULT NULL,
  `GoodContain3` varchar(300) DEFAULT NULL,
  `GoodContain4` varchar(300) DEFAULT NULL,
  `DeliveryFromSpecial` varchar(900) DEFAULT NULL,
  `DeliveryAddress` varchar(900) DEFAULT NULL,
  `ServiceTax` varchar(300) DEFAULT NULL,
  `ReceiptBillNo` varchar(300) DEFAULT NULL,
  `ReceiptBillNoAmount` varchar(300) DEFAULT NULL,
  `ReceiptBillNoDate` varchar(300) DEFAULT NULL,
  `ChallanBillNoDate` varchar(255) DEFAULT NULL,
  `ChallanBillAmount` varchar(255) DEFAULT NULL,
  `Day1` varchar(300) DEFAULT NULL,
  `Day1Place` varchar(300) DEFAULT NULL,
  `Day2` varchar(300) DEFAULT NULL,
  `Day2Place` varchar(300) DEFAULT NULL,
  `Day3` varchar(300) DEFAULT NULL,
  `Day3Place` varchar(300) DEFAULT NULL,
  `Day4` varchar(300) DEFAULT NULL,
  `Day4Place` varchar(300) DEFAULT NULL,
  `Day5` varchar(300) DEFAULT NULL,
  `Day5Place` varchar(300) DEFAULT NULL,
  `Day6` varchar(300) DEFAULT NULL,
  `Day6Place` varchar(300) DEFAULT NULL,
  `Day7` varchar(300) DEFAULT NULL,
  `Day7Place` varchar(300) DEFAULT NULL,
  `Day8` varchar(300) DEFAULT NULL,
  `Day8Place` varchar(300) DEFAULT NULL,
  `HireAmount` varchar(300) DEFAULT NULL,
  `AdvanceAmount` varchar(300) DEFAULT NULL,
  `BalanceAmount` varchar(300) DEFAULT NULL,
  `FreightCharge` varchar(300) DEFAULT NULL,
  `ReportRemarks` varchar(300) DEFAULT NULL,
  `ReceiptTime` time DEFAULT NULL,
  `ReceiptRemarks` varchar(300) DEFAULT NULL,
  `ReportDate` varchar(300) DEFAULT NULL,
  `UnloadedDate` varchar(300) DEFAULT NULL,
  `NewReceiptDate` varchar(300) DEFAULT NULL,
  `UnloadedTime` time DEFAULT NULL,
  `UnloadedRemark` varchar(300) DEFAULT NULL,
  `ReportTime` time DEFAULT NULL,
  `Success` tinyint(1) DEFAULT NULL,
  `Reject` varchar(100) DEFAULT NULL,
  `remarks` varchar(500) DEFAULT NULL,
  `CompanyId` varchar(900) DEFAULT NULL,
  KEY `Id` (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=397 DEFAULT CHARSET=latin1;

/*Table structure for table `gst` */

DROP TABLE IF EXISTS `gst`;

CREATE TABLE `gst` (
  `id` int NOT NULL AUTO_INCREMENT,
  `HSN` varchar(100) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `cgst` varchar(100) DEFAULT NULL,
  `sgst` varchar(100) DEFAULT NULL,
  `igst` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

/*Table structure for table `hsn` */

DROP TABLE IF EXISTS `hsn`;

CREATE TABLE `hsn` (
  `HSN_id` int NOT NULL AUTO_INCREMENT,
  `HSN` varchar(100) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `cgst` varchar(100) DEFAULT NULL,
  `sgst` varchar(100) DEFAULT NULL,
  `igst` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `HSN_id` (`HSN_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

/*Table structure for table `km` */

DROP TABLE IF EXISTS `km`;

CREATE TABLE `km` (
  `id` int NOT NULL AUTO_INCREMENT,
  `from` varchar(255) DEFAULT NULL,
  `to` varchar(255) DEFAULT NULL,
  `km` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=97 DEFAULT CHARSET=latin1;

/*Table structure for table `location` */

DROP TABLE IF EXISTS `location`;

CREATE TABLE `location` (
  `brachId` int NOT NULL AUTO_INCREMENT,
  `branchName` varchar(25) DEFAULT NULL,
  `branchCode` varchar(10) DEFAULT NULL,
  `branchPincode` decimal(10,0) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `email` varchar(300) DEFAULT NULL,
  `contactPerson` varchar(20) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `brachId` (`brachId`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;

/*Table structure for table `otherpayment` */

DROP TABLE IF EXISTS `otherpayment`;

CREATE TABLE `otherpayment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `otherPaymentNumber` varchar(100) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `total` varchar(1000) DEFAULT NULL,
  `bankName` varchar(100) DEFAULT NULL,
  `branchName` varchar(100) DEFAULT NULL,
  `branchCode` varchar(100) DEFAULT NULL,
  `accountNumber` varchar(100) DEFAULT NULL,
  `accountHolderName` varchar(100) DEFAULT NULL,
  `ifscCode` varchar(100) DEFAULT NULL,
  `micrCode` varchar(100) DEFAULT NULL,
  `CompanyId` int DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

/*Table structure for table `payment` */

DROP TABLE IF EXISTS `payment`;

CREATE TABLE `payment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `paymentNo` varchar(100) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `customerName` varchar(100) DEFAULT NULL,
  `total` varchar(100) DEFAULT NULL,
  `receiptAmount` varchar(100) DEFAULT NULL,
  `balanceAmount` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  `accountNumber` varchar(1000) DEFAULT NULL,
  `accountHolderName` varchar(500) DEFAULT NULL,
  `ifsc` varchar(100) DEFAULT NULL,
  `branchName` varchar(100) DEFAULT NULL,
  `branchCode` varchar(100) DEFAULT NULL,
  `bankName` varchar(100) DEFAULT NULL,
  `micr` varchar(100) DEFAULT NULL,
  `payment` varchar(100) DEFAULT NULL,
  `uploadedTime` time DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `payment_each_bill` */

DROP TABLE IF EXISTS `payment_each_bill`;

CREATE TABLE `payment_each_bill` (
  `id` int NOT NULL AUTO_INCREMENT,
  `supNo` varchar(500) DEFAULT NULL,
  `paymentNo` varchar(500) DEFAULT NULL,
  `openingAmount` varchar(500) DEFAULT NULL,
  `balanceAmount` varchar(500) DEFAULT NULL,
  `receiptAmount` varchar(500) DEFAULT NULL,
  `date` varchar(500) DEFAULT NULL,
  `companyId` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `profile_picture` */

DROP TABLE IF EXISTS `profile_picture`;

CREATE TABLE `profile_picture` (
  `userId` int NOT NULL AUTO_INCREMENT,
  `filename` mediumtext,
  `userName` varchar(100) DEFAULT NULL,
  `userEmail` varchar(100) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `companyName` varchar(100) DEFAULT NULL,
  `companyId` varchar(100) DEFAULT NULL,
  `bloodGroup` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `user_role` varchar(20) NOT NULL DEFAULT 'user',
  KEY `userId` (`userId`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=latin1;

/*Table structure for table `receipt` */

DROP TABLE IF EXISTS `receipt`;

CREATE TABLE `receipt` (
  `id` int NOT NULL AUTO_INCREMENT,
  `receiptNo` varchar(100) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `customerName` varchar(100) DEFAULT NULL,
  `total` varchar(100) DEFAULT NULL,
  `receiptAmount` varchar(100) DEFAULT NULL,
  `balanceAmount` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  `accountNumber` varchar(1000) DEFAULT NULL,
  `accountHolderName` varchar(500) DEFAULT NULL,
  `ifsc` varchar(100) DEFAULT NULL,
  `branchName` varchar(100) DEFAULT NULL,
  `branchCode` varchar(100) DEFAULT NULL,
  `bankName` varchar(100) DEFAULT NULL,
  `micr` varchar(100) DEFAULT NULL,
  `payment` varchar(100) DEFAULT NULL,
  `invoiceNo` varchar(500) DEFAULT NULL,
  `invoiceDate` varchar(500) DEFAULT NULL,
  `openingAmount` varchar(500) DEFAULT NULL,
  `uploadedTime` time DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

/*Table structure for table `receipt_each_bill` */

DROP TABLE IF EXISTS `receipt_each_bill`;

CREATE TABLE `receipt_each_bill` (
  `id` int NOT NULL AUTO_INCREMENT,
  `invoiceNo` varchar(500) DEFAULT NULL,
  `receiptNo` varchar(500) DEFAULT NULL,
  `openingAmount` varchar(500) DEFAULT NULL,
  `balanceAmount` varchar(500) DEFAULT NULL,
  `receiptAmount` varchar(500) DEFAULT NULL,
  `date` varchar(500) DEFAULT NULL,
  `companyId` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

/*Table structure for table `states` */

DROP TABLE IF EXISTS `states`;

CREATE TABLE `states` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `code` varchar(2) DEFAULT NULL,
  `tin` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=latin1;

/*Table structure for table `subotherpayment` */

DROP TABLE IF EXISTS `subotherpayment`;

CREATE TABLE `subotherpayment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `otherPaymentNumber` varchar(100) DEFAULT NULL,
  `value` varchar(100) DEFAULT NULL,
  `amount` varchar(100) DEFAULT NULL,
  `remarks` varchar(1000) DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `supplier` */

DROP TABLE IF EXISTS `supplier`;

CREATE TABLE `supplier` (
  `id` int NOT NULL AUTO_INCREMENT,
  `supplierName` varchar(100) DEFAULT NULL,
  `date` varchar(100) DEFAULT NULL,
  `bankDetails` varchar(100) DEFAULT NULL,
  `supplierNo` varchar(100) DEFAULT NULL,
  `paymentNo` varchar(100) DEFAULT NULL,
  `cgstPercentage` varchar(100) DEFAULT NULL,
  `sgstPercentage` varchar(100) DEFAULT NULL,
  `cgst` float DEFAULT NULL,
  `sgst` float DEFAULT NULL,
  `igst` float DEFAULT NULL,
  `subTotal` float DEFAULT NULL,
  `total` float DEFAULT NULL,
  `haltingCharges` float DEFAULT NULL,
  `loadingCharges` float DEFAULT NULL,
  `unloadingCharges` float DEFAULT NULL,
  `otherCharges` float DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  `openingAmount` varchar(100) DEFAULT NULL,
  `receiptAmount` varchar(100) DEFAULT NULL,
  `pendingAmount` varchar(100) DEFAULT NULL,
  `balanceAmount` varchar(100) DEFAULT NULL,
  `unloadedTime` time DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `suppliername` */

DROP TABLE IF EXISTS `suppliername`;

CREATE TABLE `suppliername` (
  `id` int NOT NULL AUTO_INCREMENT,
  `supplierName` varchar(100) DEFAULT NULL,
  `address` varchar(3000) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `contact` varchar(100) DEFAULT NULL,
  `phoneNumber` varchar(100) DEFAULT NULL,
  `mobileNumber` varchar(100) DEFAULT NULL,
  `gst` varchar(100) DEFAULT NULL,
  `panNumber` varchar(100) DEFAULT NULL,
  `msmeNumber` varchar(1000) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `cinNumber` varchar(100) DEFAULT NULL,
  `compType` varchar(100) DEFAULT NULL,
  `industrialType` varchar(100) DEFAULT NULL,
  `fax` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  `branchName` varchar(100) DEFAULT NULL,
  `branchCode` varchar(100) DEFAULT NULL,
  `bankName` varchar(100) DEFAULT NULL,
  `ifscCode` varchar(100) DEFAULT NULL,
  `micrCode` varchar(100) DEFAULT NULL,
  `accountNumber` varchar(1000) DEFAULT NULL,
  `accountHolderName` varchar(1000) DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

/*Table structure for table `truckmaster` */

DROP TABLE IF EXISTS `truckmaster`;

CREATE TABLE `truckmaster` (
  `truckMasterId` int NOT NULL AUTO_INCREMENT,
  `ownerName` varchar(30) DEFAULT NULL,
  `ownerAddress` varchar(300) DEFAULT NULL,
  `ownerMobileNumber` decimal(13,0) DEFAULT NULL,
  `ownerEmail` varchar(20) DEFAULT NULL,
  `ownerPanNumber` varchar(20) DEFAULT NULL,
  `vechileNumber` varchar(30) DEFAULT NULL,
  `typeofVechile` varchar(30) DEFAULT NULL,
  `lorryWeight` varchar(300) DEFAULT NULL,
  `unladenWeight` varchar(300) DEFAULT NULL,
  `overWeight` varchar(300) DEFAULT NULL,
  `engineeNumber` varchar(300) DEFAULT NULL,
  `chaseNumber` varchar(300) DEFAULT NULL,
  `roadTaxNumber` varchar(300) DEFAULT NULL,
  `roadTaxExpDate` varchar(300) DEFAULT NULL,
  `bankName` varchar(300) DEFAULT NULL,
  `branchName` varchar(300) DEFAULT NULL,
  `accountNumber` varchar(300) DEFAULT NULL,
  `accountHolderName` varchar(30) DEFAULT NULL,
  `ifscCode` varchar(30) DEFAULT NULL,
  `micrCode` varchar(30) DEFAULT NULL,
  `branchCode` varchar(30) DEFAULT NULL,
  `insurance` varchar(100) DEFAULT NULL,
  `insuranceExpDate` varchar(100) DEFAULT NULL,
  `fcDate` varchar(100) DEFAULT NULL,
  `CompanyId` varchar(100) DEFAULT NULL,
  KEY `truckMasterId` (`truckMasterId`)
) ENGINE=InnoDB AUTO_INCREMENT=1642 DEFAULT CHARSET=latin1;

/*Table structure for table `weight_to_rate` */

DROP TABLE IF EXISTS `weight_to_rate`;

CREATE TABLE `weight_to_rate` (
  `id` int NOT NULL AUTO_INCREMENT,
  `weight` varchar(255) DEFAULT NULL,
  `below250` varchar(255) DEFAULT NULL,
  `above250` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
