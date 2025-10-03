import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';

class SearchBarWithFilters extends StatelessWidget {
  final String hintText;
  final bool showAmount;
  final bool showStatus;
  final EdgeInsetsGeometry? margin;

  const SearchBarWithFilters({
    super.key,
    required this.hintText,
    this.showAmount = true,
    this.showStatus = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, sp, _) {
        return Container(
          margin: margin ?? const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF90A4AE)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: sp.query),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                  ),
                  onChanged: (v) => sp.setQuery(v),
                ),
              ),
              IconButton(
                tooltip: 'Filterlar',
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () => _showFilters(context, sp),
              ),
              if (sp.query.isNotEmpty)
                IconButton(
                  tooltip: 'Tozalash',
                  icon: const Icon(Icons.clear),
                  onPressed: () => sp.clearQuery(),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFilters(BuildContext context, SearchProvider sp) async {
    final from = sp.fromDate;
    final to = sp.toDate;
    final min = sp.minAmount?.toString() ?? '';
    final max = sp.maxAmount?.toString() ?? '';
    String? status = sp.status;

    final minCtrl = TextEditingController(text: min);
    final maxCtrl = TextEditingController(text: max);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune),
                  const SizedBox(width: 8),
                  const Text(
                    'Filterlar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      sp.clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Tozalash'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: from ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          sp.setDateRange(picked, sp.toDate);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        from == null
                            ? 'Boshlanish'
                            : '${from.year}-${from.month}-${from.day}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: to ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          sp.setDateRange(sp.fromDate, picked);
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        to == null
                            ? 'Tugash'
                            : '${to.year}-${to.month}-${to.day}',
                      ),
                    ),
                  ),
                ],
              ),
              if (showAmount) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimal summa',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maksimal summa',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showStatus) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  ],
                  onChanged: (v) => status = v,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final min = double.tryParse(minCtrl.text);
                    final max = double.tryParse(maxCtrl.text);
                    sp.setAmountRange(min, max);
                    sp.setStatus(status);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Qo\'llash'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
