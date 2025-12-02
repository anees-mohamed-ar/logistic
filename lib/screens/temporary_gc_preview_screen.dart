import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logistic/models/temporary_gc.dart';

class TemporaryGCPreviewScreen extends StatelessWidget {
  final TemporaryGC tempGC;

  const TemporaryGCPreviewScreen({Key? key, required this.tempGC})
    : super(key: key);

  // Helper method to format dates consistently
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not specified';
    }

    try {
      // Try to parse different date formats
      DateTime? parsedDate;

      // Try ISO format first
      try {
        parsedDate = DateTime.parse(dateString);
      } catch (e) {
        // Try other common formats
        final formats = [
          'dd-MM-yyyy',
          'dd/MM/yyyy',
          'MM-dd-yyyy',
          'MM/dd/yyyy',
          'yyyy-MM-dd',
          'dd-MM-yyyy HH:mm:ss',
          'dd/MM/yyyy HH:mm:ss',
          'yyyy-MM-dd HH:mm:ss',
        ];

        for (final format in formats) {
          try {
            parsedDate = DateFormat(format).parseStrict(dateString);
            break;
          } catch (e) {
            continue;
          }
        }
      }

      if (parsedDate != null) {
        return DateFormat('dd MMM yyyy').format(parsedDate);
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateString, error: $e');
    }

    // If all parsing fails, return the original string
    return dateString;
  }

  // Helper method to format dates with time
  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not specified';
    }

    try {
      // Try to parse different date formats
      DateTime? parsedDate;

      // Try ISO format first
      try {
        parsedDate = DateTime.parse(dateString);
      } catch (e) {
        // Try other common formats
        final formats = [
          'dd-MM-yyyy HH:mm:ss',
          'dd/MM/yyyy HH:mm:ss',
          'yyyy-MM-dd HH:mm:ss',
          'dd-MM-yyyy HH:mm',
          'dd/MM/yyyy HH:mm',
          'yyyy-MM-dd HH:mm',
        ];

        for (final format in formats) {
          try {
            parsedDate = DateFormat(format).parseStrict(dateString);
            break;
          } catch (e) {
            continue;
          }
        }
      }

      if (parsedDate != null) {
        return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
      }
    } catch (e) {
      debugPrint('Error parsing datetime: $dateString, error: $e');
    }

    // If all parsing fails, return the original string
    return dateString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${tempGC.tempGcNumber}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyGcNumber(context),
            tooltip: 'Copy GC Number',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 24),

            // Basic Information
            _buildSectionCard('Basic Information', _buildBasicInfo()),
            const SizedBox(height: 16),

            // Vehicle & Driver Information
            _buildSectionCard(
              'Vehicle & Driver Information',
              _buildVehicleDriverInfo(),
            ),
            const SizedBox(height: 16),

            // Consignor & Consignee Information
            _buildSectionCard(
              'Consignor & Consignee Information',
              _buildConsignorConsigneeInfo(),
            ),
            const SizedBox(height: 16),

            // Bill To Information
            if (tempGC.billToName?.isNotEmpty == true)
              _buildSectionCard('Bill To Information', _buildBillToInfo()),
            const SizedBox(height: 16),

            // Shipment Details
            _buildSectionCard('Shipment Details', _buildShipmentDetails()),
            const SizedBox(height: 16),

            // Package Details (Multiple)
            _buildPackageDetailsSection(),
            const SizedBox(height: 16),

            // Financial Information
            _buildSectionCard('Financial Information', _buildFinancialInfo()),
            const SizedBox(height: 16),

            // Delivery Information
            _buildSectionCard('Delivery Information', _buildDeliveryInfo()),
            const SizedBox(height: 16),

            // Additional Information
            _buildSectionCard('Additional Information', _buildAdditionalInfo()),
            const SizedBox(height: 16),

            // Status Information
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temporary GC',
                      style: TextStyle(
                        color: Colors.blue.shade100,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      tempGC.tempGcNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusChip(
                tempGC.isLocked ? 'Locked' : 'Unlocked',
                tempGC.isLocked ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                tempGC.isConverted ? 'Converted' : 'Pending',
                tempGC.isConverted ? Colors.blue : Colors.orange,
              ),
              if (tempGC.attachmentCount != null &&
                  tempGC.attachmentCount! > 0) ...[
                const SizedBox(width: 8),
                _buildAttachmentChip(tempGC.attachmentCount!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Created: ${DateFormat('dd MMM yyyy, HH:mm').format(tempGC.createdAt)}',
            style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAttachmentChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, color: Colors.purple, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count ${count == 1 ? 'File' : 'Files'}',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _buildInfoRow('GC Number', tempGC.tempGcNumber),
        _buildInfoRow('Branch', tempGC.branch),
        _buildInfoRow('GC Date', _formatDate(tempGC.gcDate)),
        _buildInfoRow('Company ID', tempGC.companyId),
      ],
    );
  }

  Widget _buildVehicleDriverInfo() {
    return Column(
      children: [
        _buildInfoRow('Truck Number', tempGC.truckNumber),
        _buildInfoRow('Vehicle Number', tempGC.vechileNumber),
        _buildInfoRow('Truck Type', tempGC.truckType),
        _buildInfoRow('Driver Name', tempGC.driverName),
        _buildInfoRow('Driver Phone', tempGC.driverPhoneNumber),
        _buildInfoRow('Broker Name', tempGC.brokerName),
        _buildInfoRow('Trip ID', tempGC.tripId),
        _buildInfoRow('PO Number', tempGC.poNumber),
      ],
    );
  }

  Widget _buildConsignorConsigneeInfo() {
    return Column(
      children: [
        _buildInfoRow('Consignor', tempGC.consignorName),
        _buildInfoRow('Consignor Address', tempGC.consignorAddress),
        _buildInfoRow('Consignor GST', tempGC.consignorGst),
        const SizedBox(height: 16),
        _buildInfoRow('Consignee', tempGC.consigneeName),
        _buildInfoRow('Consignee Address', tempGC.consigneeAddress),
        _buildInfoRow('Consignee GST', tempGC.consigneeGst),
      ],
    );
  }

  Widget _buildBillToInfo() {
    return Column(
      children: [
        _buildInfoRow('Bill To', tempGC.billToName),
        _buildInfoRow('Bill To Address', tempGC.billToAddress),
        _buildInfoRow('Bill To GST', tempGC.billToGst),
      ],
    );
  }

  Widget _buildShipmentDetails() {
    return Column(
      children: [
        _buildInfoRow('Truck From', tempGC.truckFrom),
        _buildInfoRow('Truck To', tempGC.truckTo),
        _buildInfoRow('Payment Details', tempGC.paymentDetails),
        _buildInfoRow('LC Number', tempGC.lcNo),
        _buildInfoRow('Customer Invoice No', tempGC.custInvNo),
        _buildInfoRow('Invoice Value', tempGC.invValue),
        _buildInfoRow('E-Invoice', tempGC.eInv),
        _buildInfoRow('E-Invoice Date', _formatDate(tempGC.eInvDate)),
        _buildInfoRow('EDA', tempGC.eda),
      ],
    );
  }

  Widget _buildPackageDetailsSection() {
    final packages = [
      {
        'number': '1',
        'pkg': tempGC.numberofPkg,
        'method': tempGC.methodofPkg,
        'weight': tempGC.actualWeightKgs,
        'rate': tempGC.rate,
        'total': tempGC.total,
        'goods': tempGC.goodContain,
        'km': tempGC.km,
        'charges': tempGC.charges,
        'mark': tempGC.privateMark,
      },
      {
        'number': '2',
        'pkg': tempGC.numberofPkg2,
        'method': tempGC.methodofPkg2,
        'weight': tempGC.actualWeightKgs2,
        'rate': tempGC.rate2,
        'total': tempGC.total2,
        'goods': tempGC.goodContain2,
        'km': tempGC.km2,
        'charges': tempGC.charges2,
        'mark': tempGC.privateMark2,
      },
      {
        'number': '3',
        'pkg': tempGC.numberofPkg3,
        'method': tempGC.methodofPkg3,
        'weight': tempGC.actualWeightKgs3,
        'rate': tempGC.rate3,
        'total': tempGC.total3,
        'goods': tempGC.goodContain3,
        'km': tempGC.km3,
        'charges': tempGC.charges3,
        'mark': tempGC.privateMark3,
      },
      {
        'number': '4',
        'pkg': tempGC.numberofPkg4,
        'method': tempGC.methodofPkg4,
        'weight': tempGC.actualWeightKgs4,
        'rate': tempGC.rate4,
        'total': tempGC.total4,
        'goods': tempGC.goodContain4,
        'km': tempGC.km4,
        'charges': tempGC.charges4,
        'mark': tempGC.privateMark4,
      },
    ];

    final validPackages = packages
        .where(
          (pkg) =>
              pkg['pkg']?.isNotEmpty == true ||
              pkg['method']?.isNotEmpty == true ||
              pkg['weight']?.isNotEmpty == true,
        )
        .toList();

    if (validPackages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: validPackages.map((package) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSectionCard(
            'Package ${package['number']} Details',
            Column(
              children: [
                _buildInfoRow('Number of Packages', package['pkg']),
                _buildInfoRow('Method of Packing', package['method']),
                _buildInfoRow('Actual Weight (Kgs)', package['weight']),
                _buildInfoRow('Rate', package['rate']),
                _buildInfoRow('Total', package['total']),
                _buildInfoRow('Goods Contained', package['goods']),
                _buildInfoRow('KM', package['km']),
                _buildInfoRow('Charges', package['charges']),
                _buildInfoRow('Private Mark', package['mark']),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinancialInfo() {
    return Column(
      children: [
        _buildInfoRow('Total Rate', tempGC.totalRate),
        _buildInfoRow('Total Weight', tempGC.totalWeight),
        _buildInfoRow('Hire Amount', tempGC.hireAmount),
        _buildInfoRow('Advance Amount', tempGC.advanceAmount),
        _buildInfoRow('Balance Amount', tempGC.balanceAmount),
        _buildInfoRow('Freight Charge', tempGC.freightCharge),
        _buildInfoRow('Service Tax', tempGC.serviceTax),
        _buildInfoRow('Receipt Bill No', tempGC.receiptBillNo),
        _buildInfoRow('Receipt Bill Amount', tempGC.receiptBillNoAmount),
        _buildInfoRow(
          'Receipt Bill Date',
          _formatDate(tempGC.receiptBillNoDate),
        ),
        _buildInfoRow('Challan Bill Amount', tempGC.challanBillAmount),
        _buildInfoRow(
          'Challan Bill Date',
          _formatDate(tempGC.challanBillNoDate),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Column(
      children: [
        _buildInfoRow('Delivery Date', _formatDate(tempGC.deliveryDate)),
        _buildInfoRow('E-Bill Date', _formatDate(tempGC.eBillDate)),
        _buildInfoRow('E-Bill Expiry Date', _formatDate(tempGC.eBillExpDate)),
        _buildInfoRow('Delivery From Special', tempGC.deliveryFromSpecial),
        _buildInfoRow('Delivery Address', tempGC.deliveryAddress),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        _buildInfoRow('Created By User ID', tempGC.createdByUserId.toString()),
        if (tempGC.lockedByUserId != null)
          _buildInfoRow('Locked By User ID', tempGC.lockedByUserId.toString()),
        if (tempGC.lockedAt != null)
          _buildInfoRow(
            'Locked At',
            DateFormat('dd MMM yyyy, HH:mm').format(tempGC.lockedAt!),
          ),
        if (tempGC.isConverted) ...[
          _buildInfoRow('Converted GC Number', tempGC.convertedGcNumber),
          if (tempGC.convertedByUserId != null)
            _buildInfoRow(
              'Converted By User ID',
              tempGC.convertedByUserId.toString(),
            ),
          if (tempGC.convertedAt != null)
            _buildInfoRow(
              'Converted At',
              DateFormat('dd MMM yyyy, HH:mm').format(tempGC.convertedAt!),
            ),
        ],
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Status Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                tempGC.isLocked ? Icons.lock : Icons.lock_open,
                color: tempGC.isLocked ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tempGC.isLocked
                    ? 'This GC is currently locked'
                    : 'This GC is available for editing',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                tempGC.isConverted ? Icons.check_circle : Icons.pending,
                color: tempGC.isConverted ? Colors.blue : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tempGC.isConverted
                    ? 'This GC has been converted to a permanent GC'
                    : 'This GC is pending conversion',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyGcNumber(BuildContext context) {
    Clipboard.setData(ClipboardData(text: tempGC.tempGcNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('GC Number ${tempGC.tempGcNumber} copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
