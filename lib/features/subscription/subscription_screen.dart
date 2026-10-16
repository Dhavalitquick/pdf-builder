import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:pdf_builder/core/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _buyPackage(Package package) async {
    setState(() => _isPurchasing = true);
    try {
      PurchaseResult purchaseResult = await Purchases.purchasePackage(package);
      if (purchaseResult.customerInfo.entitlements.all["premium"]?.isActive == true) {
        await SubscriptionService.instance.checkSubscriptionStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully subscribed to Premium!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // User cancelled or error
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all["premium"]?.isActive == true) {
        await SubscriptionService.instance.checkSubscriptionStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found to restore.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring purchases: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentOffering = _offerings?.current;
    final monthlyPkg = currentOffering?.monthly;
    final annualPkg = currentOffering?.annual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
        actions: [
          TextButton(
            onPressed: _isPurchasing ? null : _restorePurchases,
            child: const Text('Restore', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.stars, size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock All Pro Features',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get unlimited conversions, OCR text extraction, and password protection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  _buildFeatureRow(Icons.check_circle, 'No Advertisements'),
                  _buildFeatureRow(Icons.check_circle, 'Unlimited PDF Conversions (No 3/day limit)'),
                  _buildFeatureRow(Icons.check_circle, 'Unlimited OCR Text Extractions'),
                  _buildFeatureRow(Icons.check_circle, 'PDF Password Protection & Encryption'),
                  _buildFeatureRow(Icons.check_circle, 'Advanced Page Editor & Markup'),
                  const SizedBox(height: 36),
                  if (_isPurchasing)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // Monthly Plan Card
                    _buildPlanCard(
                      title: 'Monthly Plan',
                      price: monthlyPkg?.storeProduct.priceString ?? '\$4.99 / month',
                      subtitle: 'Billed monthly, cancel anytime.',
                      isBestValue: false,
                      onPressed: monthlyPkg != null ? () => _buyPackage(monthlyPkg) : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('RevenueCat product not configured in test sandbox yet.')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Yearly Plan Card
                    _buildPlanCard(
                      title: 'Yearly Plan (Best Value)',
                      price: annualPkg?.storeProduct.priceString ?? '\$39.99 / year',
                      subtitle: 'Save 33% with annual billing.',
                      isBestValue: true,
                      onPressed: annualPkg != null ? () => _buyPackage(annualPkg) : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('RevenueCat product not configured in test sandbox yet.')),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    required bool isBestValue,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: isBestValue ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBestValue ? Colors.deepPurple : Colors.grey.shade300,
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBestValue)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SAVE 33%',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: isBestValue ? Colors.deepPurple : Colors.grey.shade900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
