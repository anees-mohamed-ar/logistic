import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logistic/models/state_model.dart';

class SearchableDropdown<T> extends StatelessWidget {
  static const double kDefaultItemHeight = 48.0;
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool isRequired;
  final String? Function(T?)? validator;
  final bool showSearchIcon;

  const SearchableDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.isRequired = false,
    this.validator,
    this.showSearchIcon = true,
  }) : super(key: key);

  // Helper method to get a unique key for each item
  String _getItemKey(dynamic item) {
    if (item is StateModel) {
      return '${item.id}_${item.name}';
    }
    return item?.toString() ?? 'null';
  }

  // Helper to extract a human-readable label from a dropdown item
  String _getItemLabel(DropdownMenuItem<T> item) {
    final child = item.child;
    if (child is Text) {
      return child.data ?? '';
    }
    return item.value?.toString() ?? '';
  }

  Future<void> _showSearchDialog(
    BuildContext context,
    List<DropdownMenuItem<T>> items,
    T? currentValue,
  ) async {
    String query = '';

    await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        List<DropdownMenuItem<T>> filteredItems = items;

        return StatefulBuilder(
          builder: (context, setState) {
            filteredItems = items.where((item) {
              final labelStr = _getItemLabel(item).toLowerCase();
              return labelStr.contains(query.toLowerCase());
            }).toList();

            final screenHeight = MediaQuery.of(context).size.height;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: screenHeight * 0.55,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select $label',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              query = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final itemLabel = _getItemLabel(item);
                            final isSelected = item.value == currentValue;

                            return ListTile(
                              dense: true,
                              title: Text(itemLabel),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                onChanged(item.value);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Only treat the explicit `error` prop as an external error state.
    // Do NOT call the validator here, otherwise the field appears in error
    // state even before the form is validated.
    final isError = error != null && error!.isNotEmpty;

    // Log debug information
    if (kDebugMode) {
      print('Building SearchableDropdown:');
      print('- Label: $label');
      print('- Value: $value');
      print('- Items count: ${items.length}');
      print('- Is loading: $isLoading');
      print('- Error: $error');

      // Check for duplicate values
      final valueMap = <String, int>{};
      for (var item in items) {
        final key = _getItemKey(item.value);
        valueMap[key] = (valueMap[key] ?? 0) + 1;
      }

      final duplicates = valueMap.entries.where((e) => e.value > 1).toList();
      if (duplicates.isNotEmpty) {
        print('Warning: Found duplicate values in dropdown items');
        for (var dup in duplicates) {
          print('- Duplicate value: ${dup.key} (${dup.value} occurrences)');
        }
      }
    }

    // Show error state if there's an error message
    if (error != null && error!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (isRequired ? ' *' : ''),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.error, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Show loading state
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (isRequired ? ' *' : ''),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Filter out null values and ensure unique items
    final validItems = items.where((item) => item.value != null).toList();
    final uniqueItems = <String, DropdownMenuItem<T>>{};

    for (var item in validItems) {
      final key = _getItemKey(item.value);
      if (!uniqueItems.containsKey(key)) {
        uniqueItems[key] = item;
      } else if (kDebugMode) {
        print('Removing duplicate dropdown item: $key');
      }
    }

    final uniqueItemsList = uniqueItems.values.toList();

    // If current value is not in the list, set it to null
    T? currentValue = value;
    if (currentValue != null &&
        !uniqueItemsList.any((item) => item.value == currentValue)) {
      currentValue = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label + (isRequired ? ' *' : ''),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isError ? theme.colorScheme.error : null,
            ),
          ),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onTap: showSearchIcon
              ? () => _showSearchDialog(context, uniqueItemsList, currentValue)
              : null,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 200,
            ), // Ensure minimum width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              // When using validator-based errors, DropdownButtonFormField
              // will handle the error border itself. This container-level
              // border is only for explicit external errors.
              border: isError
                  ? Border.all(color: theme.colorScheme.error, width: 1.5)
                  : null,
            ),
            child: DropdownButtonFormField<T>(
              value: currentValue,
              items: uniqueItemsList,
              onChanged: showSearchIcon ? null : onChanged,
              validator: validator,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              menuMaxHeight: 300,
              itemHeight: kDefaultItemHeight,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                filled: true,
                fillColor: theme.cardColor,
                hintText: 'Select $label',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                // Let DropdownButtonFormField + Form + validator decide when
                // to show validation errors. Here we only surface explicit
                // external `error` messages.
                errorText: isError ? error : null,
                errorStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.error),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isError
                        ? theme.colorScheme.error
                        : theme.dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isError
                        ? theme.colorScheme.error
                        : theme.dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isError
                        ? theme.colorScheme.error
                        : theme.primaryColor,
                  ),
                ),
                suffixIcon: showSearchIcon
                    ? IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _showSearchDialog(
                          context,
                          uniqueItemsList,
                          currentValue,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
