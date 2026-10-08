import 'package:flutter/material.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/View/Home/Ui/Report/StockCard/stoc_card_view.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text("Report View"),
          TextButton(onPressed: (){
            ZNavigator.goto(context: context, StockCardView());
          }, child: Text("Stock Card"))
        ],
      ),

    );
  }
}
