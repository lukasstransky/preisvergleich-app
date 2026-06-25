import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showHistory = _focusNode.hasFocus && _controller.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _focusNode.unfocus();
    setState(() => _showHistory = false);
    context.read<AppState>().search(query);
  }

  void _onClear() {
    _controller.clear();
    context.read<AppState>().clearSearch();
    setState(() => _showHistory = _focusNode.hasFocus);
  }

  void _applyHistoryQuery(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: query.length));
    _focusNode.unfocus();
    setState(() => _showHistory = false);
    context.read<AppState>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasText = _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Lebensmittel suchen...',
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
                prefixIcon: GestureDetector(
                  onTap: hasText ? _onSearch : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(
                      Icons.search_rounded,
                      color: hasText
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
                suffixIcon: hasText
                    ? GestureDetector(
                        onTap: _onClear,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceHigh,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 48),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (_) {
                setState(() {
                  _showHistory =
                      _focusNode.hasFocus && _controller.text.trim().isEmpty;
                });
              },
              onSubmitted: (_) => _onSearch(),
            ),
          ),
        ),
        if (_showHistory && appState.searchHistory.isNotEmpty)
          _buildHistoryPanel(context, appState),
      ],
    );
  }

  Widget _buildHistoryPanel(BuildContext context, AppState appState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zuletzt gesucht',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    appState.clearSearchHistory();
                    setState(() => _showHistory = false);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Alle löschen',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          ...appState.searchHistory.map((query) => InkWell(
                onTap: () => _applyHistoryQuery(query),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 17, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(query,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary)),
                      ),
                      GestureDetector(
                        onTap: () =>
                            appState.removeFromSearchHistory(query),
                        child: const Icon(Icons.close,
                            size: 15, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
