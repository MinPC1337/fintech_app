import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_entity.dart';
import '../widgets/budget/budget_category_list.dart' show CategoryListItem;
import '../widgets/budget/budget_glass_card.dart';

class BudgetCategoryTransactionsPage extends StatefulWidget {
  const BudgetCategoryTransactionsPage({super.key, required this.item});

  final CategoryListItem item;

  @override
  State<BudgetCategoryTransactionsPage> createState() =>
      _BudgetCategoryTransactionsPageState();
}

class _BudgetCategoryTransactionsPageState
    extends State<BudgetCategoryTransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'newest'; // newest, oldest, highest, lowest
  DateTimeRange? _dateRange;
  bool _isPickerLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  List<TransactionEntity> get _filteredTransactions {
    List<TransactionEntity> list = widget.item.transactions.toList();

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((t) {
        final noteMatch = t.note.toLowerCase().contains(query);
        final titleMatch = widget.item.title.toLowerCase().contains(query);
        return noteMatch || titleMatch;
      }).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      final end = _dateRange!.end.add(const Duration(days: 1));
      list = list.where((t) {
        return t.timestamp.isAfter(
              _dateRange!.start.subtract(const Duration(milliseconds: 1)),
            ) &&
            t.timestamp.isBefore(end);
      }).toList();
    }

    // Sort
    switch (_sortOption) {
      case 'newest':
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'oldest':
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'highest':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'lowest':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayedTransactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: _buildHeaderCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: _buildSearchAndFilter(),
                ),
              ),
              if (displayedTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Không có giao dịch nào trong tháng này'
                          : 'Không tìm thấy giao dịch phù hợp',
                      style: const TextStyle(color: kTextSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final transaction = displayedTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BudgetGlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kElectricBlue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: kElectricBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.note.isNotEmpty
                                          ? transaction.note
                                          : widget.item.category.name,
                                      style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(transaction.timestamp),
                                      style: const TextStyle(
                                        color: kTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '-${_formatCurrency(transaction.amount)}',
                                style: const TextStyle(
                                  color: kRose,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: displayedTransactions.length),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
          if (_isPickerLoading)
            Container(
              color: kBgColor.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kElectricBlue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    setState(() {
      _isPickerLoading = true;
    });

    // Cho phép UI render trạng thái loading mượt mà hơn trước khi bị block
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 5);

    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kElectricBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E284A), // Sáng hơn nền một chút để dễ nhìn
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E284A),
          ),
          child: child!,
        );
      },
    );

    if (mounted) {
      setState(() {
        _isPickerLoading = false;
        if (range != null) {
          _dateRange = range;
        }
      });
    }
  }

  Widget _buildSearchAndFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: kTextSecondary.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm giao dịch...',
                          hintStyle: TextStyle(
                            color: kTextSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: kTextSecondary.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isPickerLoading ? null : _pickDateRange,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _dateRange != null
                      ? kElectricBlue.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _dateRange != null
                        ? kElectricBlue
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: _dateRange != null ? kElectricBlue : Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              initialValue: _sortOption,
              onSelected: (value) {
                setState(() {
                  _sortOption = value;
                });
              },
              color: const Color(0xFF1E284A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              itemBuilder: (context) => [
                _buildSortMenuItem('Mới nhất', 'newest'),
                _buildSortMenuItem('Cũ nhất', 'oldest'),
                _buildSortMenuItem('Chi nhiều nhất', 'highest'),
                _buildSortMenuItem('Chi ít nhất', 'lowest'),
              ],
            ),
          ],
        ),
        if (_dateRange != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kElectricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kElectricBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 16, color: kElectricBlue),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                    style: const TextStyle(
                      color: kElectricBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _dateRange = null),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: kElectricBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String label, String value) {
    final isSelected = _sortOption == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? kElectricBlue : kTextPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, color: kElectricBlue, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final barColor = widget.item.isOverBudget ? kRose : widget.item.iconColor;

    return BudgetGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.item.iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: widget.item.emoji != null && widget.item.emoji!.isNotEmpty
                ? Text(widget.item.emoji!, style: const TextStyle(fontSize: 24))
                : Icon(Icons.category, color: widget.item.iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '${widget.item.spent} / ',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: widget.item.limit,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: widget.item.ratio,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        widget.item.percentage,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: barColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
