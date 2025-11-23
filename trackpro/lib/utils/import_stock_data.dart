import '../services/api_service.dart';

Future<void> importStockData() async {
  await Future.delayed(const Duration(milliseconds: 100));
  final stockData = [
    {'toolName': 'CCMT D6 D2 D4 CM.CP2430', 'currentStock': 0, 'remarks': 'BACK SPOT'},
    {'toolName': 'ASMT11T320PDPR-MJAH120', 'currentStock': 9, 'remarks': 'NIL'},
    {'toolName': 'LMMU110716PNER-MJ AH120', 'currentStock': 33, 'remarks': 'C95'},
    {'toolName': 'SCMT09T308XS-XT110', 'currentStock': 5, 'remarks': 'HAND CHAMFERING MACHINE'},
    {'toolName': 'SEMT13T3AGSN-JM VP15TF', 'currentStock': 255, 'remarks': 'DIA 250 & 125 FINISHING INSERTS'},
    {'toolName': 'APMT1604PDER-M2ASM30', 'currentStock': 1, 'remarks': 'C95'},
    {'toolName': 'APMT1604-M2AS20', 'currentStock': 97, 'remarks': 'C95'},
    {'toolName': 'TOMT100404PDER-MJ AH120', 'currentStock': 18, 'remarks': 'DIA 40 CUTTER FINISHING TRIANGLE INSERT'},
    {'toolName': 'TCMT220408MMT1', 'currentStock': 5, 'remarks': '250 ROUGHING BORINGBAR INSERT'},
    {'toolName': 'TCMT110304-KF 3210', 'currentStock': 6, 'remarks': 'SANDVIK FINISHING BORING BAR'},
    {'toolName': 'TCMT 09 02 04-KF3210', 'currentStock': 7, 'remarks': 'SANDVIK FINISHING BORING BAR'},
    {'toolName': 'SNKX 1606 ANER-MK PH5320', 'currentStock': 2, 'remarks': 'C95'},
    {'toolName': 'TNMU1207R16PER-MJ AH120', 'currentStock': 28, 'remarks': 'DIA 80 CUTTER TRIANGLE INSERT'},
    {'toolName': 'TNMU120708PER-MJ AH3225', 'currentStock': 5, 'remarks': 'DIA 80 CUTTER'},
    {'toolName': 'OAKU 060508SR-M50 CTPM240', 'currentStock': 10, 'remarks': 'C95'},
    {'toolName': 'SDMT 1205ZZSN-31 CTCK215', 'currentStock': 61, 'remarks': 'DIA 63, ROUGHING INSERTS'},
    {'toolName': 'SNMU1706ANPR-MJ T1215', 'currentStock': 7, 'remarks': 'DIA 125 CUTTER ROUGHING'},
    {'toolName': 'ONMU0705ANPN-MJ T1215', 'currentStock': 127, 'remarks': 'DIA 125 CUTER,16 CORNER'},
    {'toolName': 'LQMU110716PNER-MJ AH725', 'currentStock': 4, 'remarks': 'DIA 40, CUTTER ROUGHING'},
    {'toolName': 'JKTCI-WNMU060408', 'currentStock': 32, 'remarks': 'DIA 63,80 & 50 CUTTER FINISHING'},
    {'toolName': 'JDMT100308R-FW', 'currentStock': 3, 'remarks': '25 CUTTER INSERT'},
    {'toolName': 'JDMT070208R 160323', 'currentStock': 8, 'remarks': 'NIL'},
    {'toolName': 'JKTCI-TPGH090202L', 'currentStock': 10, 'remarks': 'FINISHING BORING BAR INSERTS MAX USED FOR 84 DIA'},
    {'toolName': 'WCGX040204-ZV', 'currentStock': 16, 'remarks': '21 "U" DRILL INSERTS (TOOL DAMAGED)'},
    {'toolName': 'ONHU0705ANPR-W AH120', 'currentStock': 3, 'remarks': 'C95'},
    {'toolName': 'TOMT150604PDER-MJ AH120', 'currentStock': 4, 'remarks': '63 finishing triangle inserts'},
    {'toolName': 'SDMT 1205ZZSN-29 CTCP230', 'currentStock': 34, 'remarks': '63 CUTTER ROUGHING INSERTS FOR MS ONLY'},
    {'toolName': 'XOMT130406-PD', 'currentStock': 18, 'remarks': '39"U"DRILL'},
    {'toolName': 'SPMT130410-PD', 'currentStock': 18, 'remarks': '39"U"DRILL'},
    {'toolName': 'XOMT15M508-PD', 'currentStock': 17, 'remarks': '45&43"U"DRILL'},
    {'toolName': 'SPMT15M510-PD', 'currentStock': 17, 'remarks': '45&43"U"DRILL'},
    {'toolName': 'LQMU110704PNER-MJ AH725', 'currentStock': 20, 'remarks': 'DIA 40, CUTTER FINISHING 0.4 RADIUS'},
    {'toolName': 'LQMU110708PNER-MJ AH725', 'currentStock': 4, 'remarks': 'DIA 40, CUTTER FINISHING 0.8 RADIUS'},
    {'toolName': 'SPGT090408-XT830', 'currentStock': 8, 'remarks': 'DIA 26 COUNTER CUTTER'},
    {'toolName': 'SPMG07T308-PGLF6118', 'currentStock': 16, 'remarks': 'DIA 26 AND 25 U DRILL'},
    {'toolName': 'SPMG060204-PGLF6118 (21)', 'currentStock': 5, 'remarks': 'DIA 21 U DRILL'},
    {'toolName': 'SPMG060204-PGLF6118 (17.5)', 'currentStock': 6, 'remarks': 'DIA 17.5 UDRILL'},
    {'toolName': 'TPGX110304L NX2525', 'currentStock': 5, 'remarks': 'FINISHING BORING BAR INSERTS MAX USED FOR 250 DIA'},
    {'toolName': 'CCMT060204-CM', 'currentStock': 4, 'remarks': 'DIA 17.5 AND 20 BACK SPOTFACE INSERT'},
    {'toolName': 'SPMT07T308-ND1', 'currentStock': 10, 'remarks': '26.5 U DRILL INSERT'},
    {'toolName': 'TCMT16T308XS-XT110', 'currentStock': 8, 'remarks': '60 CORE DRILL INSERT'},
    {'toolName': 'TCMT16T304XS-XT110', 'currentStock': 11, 'remarks': '45 DEGREE CHAMFER TOOL INSERT'},
    {'toolName': 'CCMT09T308-CM CP2430', 'currentStock': 8, 'remarks': '40 BACK SPOT INSERT'},
    {'toolName': 'JNMU0603ER-B', 'currentStock': 1, 'remarks': 'DIA 25 CUTTER'},
    {'toolName': 'SONT 104408ER-M30 CTPP430', 'currentStock': 3, 'remarks': '33 UDRILL'},
    {'toolName': 'JDMT070202R', 'currentStock': 8, 'remarks': 'NIL'},
    {'toolName': 'APMT1604PDER-PR RX2000S', 'currentStock': 11, 'remarks': 'NIL'},
    {'toolName': 'SCMT09T308GM-XT930-C', 'currentStock': 8, 'remarks': '45 DEGREE TOP AND BOTTOM CHAMFER TOOL'},
  ];

  for (var stock in stockData) {
    try {
      final currentStock = stock['currentStock'] as int;
      await ApiService.createToolStock(
        toolName: stock['toolName'] as String,
        currentStock: currentStock,
        minimumStock: 5,
        maximumStock: currentStock + 50,
        reorderLevel: 10,
        reorderQuantity: 20,
        unit: 'pieces',
        location: 'Tool Room',
        notes: stock['remarks'] as String,
      );
      print('✓ Added: ${stock['toolName']}');
    } catch (e) {
      print('✗ Skipped: ${stock['toolName']}');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
