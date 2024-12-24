// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCAdditionalInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCCustomerInfoInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCEMITransactionInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCShipmentInfoInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum SdkType { LIVE, TESTBOX }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SSLCommerzScreen(),
    );
  }
}

class SSLCommerzScreen extends StatefulWidget {
  const SSLCommerzScreen({super.key});

  @override
  _SSLCommerzScreenState createState() => _SSLCommerzScreenState();
}

class _SSLCommerzScreenState extends State<SSLCommerzScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  SdkType _sdkType = SdkType.LIVE;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SSLCommerz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                  label: "Store ID",
                  initialValue: "invit6763fcef8bce7",
                  onSaved: (value) => _formData['store_id'] = value,
                  validator: _validateNotEmpty),
              _buildTextField(
                  label: "Store Password",
                  initialValue: "invit6763fcef8bce7@ssl",
                  onSaved: (value) => _formData['store_password'] = value,
                  validator: _validateNotEmpty),
              _buildRadioButtons(),
              _buildTextField(
                  label: "Phone Number",
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _formData['phone'] = value),
              _buildTextField(
                  label: "Payment Amount",
                  initialValue: "10",
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) =>
                      _formData['amount'] = double.tryParse(value ?? '0'),
                  validator: _validateNotEmpty),
              _buildTextField(
                  label: "Enter Multi Card",
                  onSaved: (value) => _formData['multicard'] = value),
              ElevatedButton(
                onPressed: _onPayNowPressed,
                child: Text("Pay now"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      String? initialValue,
      TextInputType keyboardType = TextInputType.text,
      FormFieldSetter<String>? onSaved,
      FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          hintText: label,
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildRadioButtons() {
    return Row(
      children: [
        _buildRadio(SdkType.TESTBOX, "TESTBOX"),
        _buildRadio(SdkType.LIVE, "LIVE"),
      ],
    );
  }

  Widget _buildRadio(SdkType type, String label) {
    return Row(
      children: [
        Radio(
          value: type,
          groupValue: _sdkType,
          activeColor: Colors.blue,
          onChanged: (value) {
            setState(() => _sdkType = value as SdkType);
          },
        ),
        Text(label),
      ],
    );
  }

  String? _validateNotEmpty(String? value) {
    return (value == null || value.isEmpty) ? "Please input value" : null;
  }

  Future<void> _onPayNowPressed() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _startSSLCommerzTransaction();
    }
  }

  Future<void> _startSSLCommerzTransaction() async {
    Sslcommerz sslcommerz = Sslcommerz(
      initializer: SSLCommerzInitialization(
        ipn_url: "www.ipnurl.com",
        multi_card_name: _formData['multicard'],
        currency: SSLCurrencyType.BDT,
        product_category: "Food",
        sdkType: _sdkType == SdkType.TESTBOX
            ? SSLCSdkType.TESTBOX
            : SSLCSdkType.LIVE,
        store_id: _formData['store_id'],
        store_passwd: _formData['store_password'],
        total_amount: _formData['amount'],
        tran_id: "1231123131212",
      ),
    );

    sslcommerz
        .addShipmentInfoInitializer(
          sslcShipmentInfoInitializer: SSLCShipmentInfoInitializer(
            shipmentMethod: "yes",
            numOfItems: 5,
            shipmentDetails: ShipmentDetails(
                shipAddress1: "Ship address 1",
                shipCity: "Faridpur",
                shipCountry: "Bangladesh",
                shipName: "Ship name 1",
                shipPostCode: "7860"),
          ),
        )
        .addCustomerInfoInitializer(
          customerInfoInitializer: SSLCCustomerInfoInitializer(
            customerState: "Chattogram",
            customerName: "Abu Sayed Chowdhury",
            customerEmail: "abc@gmail.com",
            customerAddress1: "Anderkilla",
            customerCity: "Chattogram",
            customerPostCode: "200",
            customerCountry: "Bangladesh",
            customerPhone: _formData['phone'],
          ),
        )
        .addEMITransactionInitializer(
            sslcemiTransactionInitializer: SSLCEMITransactionInitializer(
                emi_options: 1, emi_max_list_options: 9, emi_selected_inst: 0))
        .addAdditionalInitializer(
          sslcAdditionalInitializer: SSLCAdditionalInitializer(
            valueA: "value a",
            valueB: "value b",
            valueC: "value c",
            valueD: "value d",
            extras: {"key": "key", "key2": "key2"},
          ),
        );

    SSLCTransactionInfoModel result = await sslcommerz.payNow();
    _displayPaymentStatus(result);
  }

  void _displayPaymentStatus(SSLCTransactionInfoModel result) {
    String message;
    Color bgColor;

    switch (result.status?.toLowerCase()) {
      case "failed":
        message = "Transaction Failed";
        bgColor = Colors.red;
        break;
      case "closed":
        message = "SDK Closed by User";
        bgColor = Colors.orange;
        break;
      default:
        message =
            "Transaction ${result.status} - Amount: ${result.amount ?? 0}";
        bgColor = Colors.green;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
