import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const CampusStoreApp());

class Product {
  final String name, category;
  final double price;
  final IconData icon;
  const Product(this.name, this.category, this.price, this.icon);
}

class CampusStoreApp extends StatelessWidget {
  const CampusStoreApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campus Store POS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
          scaffoldBackgroundColor: const Color(0xFFF1F3F6),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D47A1),
              foregroundColor: Colors.white),
          cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),
          inputDecorationTheme:
              const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const PosHome(),
      );
}

class PosHome extends StatefulWidget {
  const PosHome({super.key});
  @override
  State<PosHome> createState() => _PosHomeState();
}

class _PosHomeState extends State<PosHome> {
  final products = const [
    Product('Coffee', 'Drinks', 45, Icons.coffee),
    Product('Sandwich', 'Food', 50, Icons.lunch_dining),
    Product('Soft Drink', 'Drinks', 35, Icons.local_drink),
    Product('Cookies', 'Snacks', 25, Icons.cookie),
    Product('Bottled Water', 'Drinks', 20, Icons.water_drop),
    Product('Chocolate', 'Snacks', 25, Icons.grid_view_rounded),
  ];
  final Map<Product, int> cart = {};
  int screen =
      0; // 0 order, 1 review, 2 payment, 3 cash, 4 qr, 5 card, 6 success, 7 receipt
  String category = 'All';
  String paymentMethod = '';
  String cashText = '';
  double amountPaid = 0, change = 0;
  String transactionNo = '';
  DateTime? transactionDate;
  bool processing = false;
  String? cashError;
  int txnCounter = 1;

  double get total => cart.entries.fold(0, (s, e) => s + e.key.price * e.value);
  int get itemCount => cart.values.fold(0, (s, q) => s + q);
  List<Product> get visibleProducts => category == 'All'
      ? products
      : products.where((p) => p.category == category).toList();
  String money(double v) => '₱${v.toStringAsFixed(2)}';

  void toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 1)));

  void add(Product p) {
    setState(() => cart[p] = (cart[p] ?? 0) + 1);
    toast('Product added - ${p.name}');
  }

  void adjust(Product p, int delta) {
    final next = (cart[p] ?? 0) + delta;
    if (next <= 0) {
      setState(() => cart.remove(p));
      toast('${p.name} removed');
    } else {
      setState(() => cart[p] = next);
    }
  }

  void remove(Product p) {
    setState(() => cart.remove(p));
    toast('${p.name} removed');
  }

  void finishPayment(String method, double paid) {
    setState(() {
      paymentMethod = method;
      amountPaid = paid;
      change = paid - total;
      transactionDate = DateTime.now();
      transactionNo =
          'TXN-${transactionDate!.year}-${txnCounter.toString().padLeft(5, '0')}';
      txnCounter++;
      processing = false;
      screen = 6;
    });
    toast('Transaction completed successfully');
  }

  void resetTransaction() {
    setState(() {
      cart.clear();
      screen = 0;
      category = 'All';
      paymentMethod = '';
      cashText = '';
      amountPaid = 0;
      change = 0;
      transactionNo = '';
      transactionDate = null;
      cashError = null;
      processing = false;
    });
    toast('New transaction started - previous order cleared');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: const Row(children: [
            Icon(Icons.shopping_cart, size: 30),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Campus Store POS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Self-Service Kiosk', style: TextStyle(fontSize: 13))
            ])
          ]),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 24), child: _steps())
          ],
        ),
        body: SafeArea(
            child: Padding(padding: const EdgeInsets.all(20), child: _body())),
      );

  Widget _steps() {
    final active = screen == 0
        ? 0
        : screen == 1
            ? 1
            : (screen >= 2 && screen <= 6)
                ? 2
                : 3;
    const names = ['Order', 'Review', 'Payment', 'Receipt'];
    return Row(
        children: List.generate(
            4,
            (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            radius: 14,
                            backgroundColor: i <= active
                                ? (i < active ? Colors.green : Colors.white)
                                : Colors.blueGrey.shade700,
                            foregroundColor: i == active
                                ? Colors.blue.shade900
                                : Colors.white,
                            child: Text(i < active ? '✓' : '${i + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        const SizedBox(height: 3),
                        Text(names[i], style: const TextStyle(fontSize: 11)),
                      ]),
                )));
  }

  Widget _body() {
    switch (screen) {
      case 0:
        return _order();
      case 1:
        return _review();
      case 2:
        return _paymentMethods();
      case 3:
        return _cash();
      case 4:
        return _qr();
      case 5:
        return _card();
      case 6:
        return _success();
      default:
        return _receipt();
    }
  }

  Widget _order() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tap a product to add it to your order',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Drinks', 'Food', 'Snacks']
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c),
                              selected: category == c,
                              onSelected: (_) {
                                setState(() {
                                  category = c;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        childAspectRatio: 1.25,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: visibleProducts
                            .map((p) => _productCard(p))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: _cartPanel(),
          ),
        ],
      );

  Widget _productCard(Product p) => InkWell(
      onTap: () => add(p),
      borderRadius: BorderRadius.circular(10),
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(p.icon, size: 50, color: Colors.blue.shade700),
                    const SizedBox(height: 12),
                    Text(p.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 5),
                    Text(money(p.price),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700))
                  ]))));

  Widget _cartPanel() => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Your Order',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('$itemCount items')
            ]),
            const Divider(height: 28),
            Expanded(
                child: cart.isEmpty
                    ? const Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Your order is empty',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                            'Tap a product on the left to add it to your order.')
                      ]))
                    : ListView(
                        children: cart.entries
                            .map((e) => _cartRow(e.key, e.value))
                            .toList())),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(money(total),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                    onPressed:
                        cart.isEmpty ? null : () => setState(() => screen = 1),
                    child: const Text('Proceed to Review →',
                        style: TextStyle(fontSize: 17))))
          ])));

  Widget _cartRow(Product p, int q) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(p.icon, size: 34),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${money(p.price)} each', style: const TextStyle(fontSize: 12))
        ])),
        IconButton(
            onPressed: () => adjust(p, -1), icon: const Icon(Icons.remove)),
        Text('$q', style: const TextStyle(fontSize: 17)),
        IconButton(onPressed: () => adjust(p, 1), icon: const Icon(Icons.add)),
        SizedBox(
            width: 80,
            child: Text(money(p.price * q),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        IconButton(
            onPressed: () => remove(p),
            color: Colors.red,
            icon: const Icon(Icons.delete_outline))
      ]));

  Widget _review() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Review your order',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text(
                'Check your items before paying. Tap Back to make changes - your items stay in the cart.'),
            const SizedBox(height: 16),
            Expanded(
                child: Card(
                    child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  color: Colors.blueGrey.shade50,
                  child: const Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text('PRODUCT',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('QUANTITY')),
                    Expanded(child: Text('UNIT PRICE')),
                    Expanded(child: Text('SUBTOTAL'))
                  ])),
              ...cart.entries.map((e) => Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text(e.key.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('${e.value}')),
                    Expanded(child: Text(money(e.key.price))),
                    Expanded(
                        child: Text(money(e.key.price * e.value),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)))
                  ]))),
              const Spacer(),
              Container(
                  padding: const EdgeInsets.all(18),
                  color: Colors.blue.shade50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$itemCount items'),
                        Text('Total Amount  ${money(total)}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold))
                      ]))
            ]))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => setState(() => screen = 0),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'))),
              const SizedBox(width: 14),
              Expanded(
                  flex: 2,
                  child: FilledButton(
                      onPressed: () => setState(() => screen = 2),
                      child: const Text('Continue to Payment →')))
            ])
          ])));

  Widget _paymentMethods() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('How would you like to pay?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerRight,
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          const Text('AMOUNT DUE'),
                          Text(money(total),
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold))
                        ])))),
            const SizedBox(height: 18),
            Expanded(
                child: Row(children: [
              _payCard(
                  Icons.payments,
                  'Cash',
                  'Enter the amount you are paying. Change is computed for you.',
                  3),
              const SizedBox(width: 14),
              _payCard(Icons.qr_code, 'QR Payment',
                  'Scan with a supported e-wallet or banking app.', 4),
              const SizedBox(width: 14),
              _payCard(Icons.credit_card, 'Credit / Debit Card',
                  'Tap, insert, or swipe your card at the reader.', 5),
            ])),
            const SizedBox(height: 16),
            SizedBox(
                width: 250,
                child: OutlinedButton.icon(
                    onPressed: () => setState(() => screen = 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Order')))
          ])));

  Widget _payCard(IconData icon, String title, String desc, int target) =>
      Expanded(
          child: InkWell(
              onTap: () => setState(() => screen = target),
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 64, color: Colors.blue.shade700),
                            const SizedBox(height: 18),
                            Text(title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(desc, textAlign: TextAlign.center)
                          ])))));

  void key(String k) {
    setState(() {
      cashError = null;

      if (k == 'C') {
        cashText = '';
      } else if (k == 'B') {
        if (cashText.isNotEmpty) {
          cashText = cashText.substring(0, cashText.length - 1);
        }
      } else {
        cashText += k;
      }
    });
  }

  double get cashValue => double.tryParse(cashText) ?? 0;
  void payCash() {
    if (cashText.isEmpty || cashValue < total) {
      setState(() => cashError =
          'Insufficient payment. Please enter at least ${money(total)}. You are short by ${money((total - cashValue).clamp(0, double.infinity))}.');
      return;
    }
    finishPayment('Cash', cashValue);
  }

  Widget _cash() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Cash Payment',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _info('Total Amount', money(total)),
                  const SizedBox(height: 12),
                  const Text('Amount Paid',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                      readOnly: true,
                      controller: TextEditingController(
                          text: cashText.isEmpty ? '' : money(cashValue)),
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  if (cashError != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: Colors.red.shade50,
                            child: Text(cashError!,
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 12),
                  const Text('Quick Amounts'),
                  Wrap(
                      spacing: 8,
                      children: [
                        ('Exact', total),
                        ('₱200', 200.0),
                        ('₱500', 500.0),
                        ('₱1,000', 1000.0)
                      ]
                          .map((x) => OutlinedButton(
                              onPressed: () => setState(() {
                                    cashText = x.$2.toStringAsFixed(0);
                                    cashError = null;
                                  }),
                              child: Text(x.$1)))
                          .toList()),
                  const SizedBox(height: 12),
                  _info('Change',
                      cashValue >= total ? money(cashValue - total) : '—',
                      green: cashValue >= total),
                ])),
            const SizedBox(width: 24),
            SizedBox(
                width: 370,
                child: Column(children: [
                  Expanded(
                      child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: [
                            '1',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                            '8',
                            '9',
                            'C',
                            '0',
                            'B'
                          ]
                              .map((k) => OutlinedButton(
                                  onPressed: () => key(k),
                                  child: k == 'B'
                                      ? const Icon(Icons.backspace_outlined)
                                      : Text(k == 'C' ? 'Clear' : k,
                                          style:
                                              const TextStyle(fontSize: 22))))
                              .toList())),
                  SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                          onPressed: payCash, child: const Text('Pay Now'))),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () => setState(() => screen = 2),
                          child: const Text('Change Payment Method')))
                ]))
          ])));

  Widget _info(String label, String value, {bool green = false}) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: green ? Colors.green.shade700 : null))
          ])));

  Widget _qr() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Row(children: [
            Expanded(
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(28),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.qr_code_2, size: 220),
                          Text(
                              'Ref: QR-${transactionNo.isEmpty ? 'PENDING' : transactionNo}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))
                        ])))),
            const SizedBox(width: 28),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Text('QR Payment (Simulated)',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _info('Amount to Pay', money(total)),
                  const SizedBox(height: 16),
                  const Text(
                      '1. Scan the QR code using your supported payment application.\n\n2. Verify and approve the displayed amount.\n\n3. Tap Confirm Payment below.'),
                  const SizedBox(height: 16),
                  const Text(
                      'This is a simulated payment. No actual payment will be processed.'),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => setState(() => screen = 2),
                            child: const Text('Back'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: FilledButton(
                            onPressed: () => finishPayment('QR Payment', total),
                            child: const Text('Confirm Payment')))
                  ])
                ]))
          ])));

  Widget _card() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.credit_card, size: 110, color: Colors.deepPurple),
            const SizedBox(height: 12),
            const Text('Credit / Debit Card Payment (Simulated)',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _info('Amount Due', money(total)),
            const SizedBox(height: 14),
            const Text('Please tap, insert, or swipe your card.',
                style: TextStyle(fontSize: 18)),
            if (processing) ...[
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text(
                  'Processing payment... Do not remove your card until the payment is complete.')
            ],
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed:
                          processing ? null : () => setState(() => screen = 2),
                      child: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: processing
                          ? null
                          : () async {
                              setState(() => processing = true);
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted) {
                                finishPayment('Credit / Debit Card', total);
                              }
                            },
                      child: Text(
                          processing ? 'Processing...' : 'Process Payment')))
            ])
          ])));

  Widget _success() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.green,
                        child:
                            Icon(Icons.check, size: 54, color: Colors.white)),
                    const SizedBox(height: 16),
                    Text('Payment Successful',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                    const Text(
                        'Transaction completed successfully. Thank you!'),
                    const SizedBox(height: 22),
                    _detail('Transaction No.', transactionNo),
                    _detail('Payment Method', paymentMethod),
                    _detail('Transaction Amount', money(total)),
                    _detail('Amount Paid', money(amountPaid)),
                    _detail('Change', money(change)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                            onPressed: () => setState(() => screen = 7),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('View Receipt')))
                  ])))));
  Widget _detail(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(a),
        Text(b, style: const TextStyle(fontWeight: FontWeight.bold))
      ]));

  Widget _receipt() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                  child: Text('CAMPUS STORE POS',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold))),
                              const Center(
                                  child: Text(
                                      'Self-Service Kiosk · Official Digital Receipt')),
                              const Divider(height: 28),
                              _detail('Transaction No.', transactionNo),
                              _detail('Date',
                                  transactionDate.toString().substring(0, 19)),
                              const Divider(),
                              const Row(children: [
                                Expanded(
                                    flex: 2,
                                    child: Text('ITEM',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                Expanded(child: Text('QTY')),
                                Expanded(child: Text('SUBTOTAL'))
                              ]),
                              ...cart.entries.map((e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(children: [
                                    Expanded(
                                        flex: 2,
                                        child: Text(
                                            '${e.key.name}\n${e.value} × ${money(e.key.price)}')),
                                    Expanded(child: Text('${e.value}')),
                                    Expanded(
                                        child:
                                            Text(money(e.key.price * e.value)))
                                  ]))),
                              const Divider(),
                              _detail('TOTAL', money(total)),
                              _detail('Payment Method', paymentMethod),
                              _detail('Amount Paid', money(amountPaid)),
                              _detail('Change', money(change)),
                              _detail('Status', 'Payment Successful'),
                              const Spacer(),
                              const Center(
                                  child: Text('Thank you for your purchase!'))
                            ])))),
            const SizedBox(width: 22),
            SizedBox(
                width: 300,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 70),
                      const SizedBox(height: 12),
                      const Text('Your receipt',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'Keep this for your records. Start a new transaction when you are done.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 22),
                      SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                              onPressed: resetTransaction,
                              icon: const Icon(Icons.add),
                              label: const Text('New Transaction'))),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                              onPressed: () =>
                                  toast('Print simulation complete'),
                              icon: const Icon(Icons.print),
                              label: const Text('Print Receipt')))
                    ]))
          ])));
}
