import 'package:flutter/material.dart';
import 'package:hr_attendant/models/claim.dart';
import 'package:hr_attendant/provider/claimProvider.dart';
import 'package:hr_attendant/screens/claim/SubmitClaimScreen.dart';
import 'package:hr_attendant/widgets/home/buildCircleButton.dart';
import 'package:provider/provider.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Provider.of<ClaimProvider>(context, listen: false).fetchClaims();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Claims'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<ClaimProvider>(context, listen: false).fetchClaims(),
        child: Consumer<ClaimProvider>(
          builder: (ctx, claimProvider, _) {
            if (claimProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (claimProvider.errorMessage != null) {
              return Center(
                child: Text(claimProvider.errorMessage!),
              );
            } else {
              return ListView.builder(
                itemCount: claimProvider.claims.length,
                itemBuilder: (ctx, i) => ClaimItem(claimProvider.claims[i]),
              );
            }
          },
        ),
      ),
      floatingActionButton: CircleButton(
          text: 'Submit Claim',
          buttonSize: ButtonSize.medium,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubmitClaimScreen(),
              ),
            );
          }),
    );
  }
}

class ClaimItem extends StatelessWidget {
  final Claim claim;

  const ClaimItem(this.claim, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text("${claim.claimTypeDesc} - ${claim.providerName}"),
        subtitle: Text(
          claim.visitDate,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(claim.statusDesc),
        // Add more fields as needed
      ),
    );
  }
}
