import 'package:flutter/material.dart';
import 'package:hr_attendant/provider/PayslipProvider.dart';
import 'package:hr_attendant/screens/pdfViewer.dart';
import 'package:provider/provider.dart';

class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payslips'),
      ),
      body: FutureBuilder(
        future: Provider.of<PayslipProvider>(context, listen: false)
            .fetchPayslips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Consumer<PayslipProvider>(
              builder: (ctx, payslipProvider, _) => ListView.builder(
                itemCount: payslipProvider.payslips.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    title: Text(
                        '${payslipProvider.payslips[i].year} - ${payslipProvider.payslips[i].month}'),
                    onTap: () async {
                      final url = payslipProvider.payslips[i].imgPaths[0];
                      print(url);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDF(url),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
