import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../constants/my_colors.dart';
import '../../../../core/models/store_mobile_order.dart';
import '../../../../services/mobile_order_pay/store/store_cache_service.dart';
import '../../../../shared/helpers/local_database.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

/// 店舗検索機能
class StoreSearch extends StatefulWidget {
  const StoreSearch({
    super.key,
    required this.onValueSelected,
    required this.backMain,
    required this.isMainView,
  });
  static String routeName = 'mobileorder_search_store';
  final void Function(StoreMobileOrder) onValueSelected;
  final VoidCallback backMain;
  final bool isMainView;

  @override
  State<StoreSearch> createState() => _StoreSearchState();
}

class _StoreSearchState extends State<StoreSearch> {
  final StoreCacheService cacheService = StoreCacheService();
  List<StoreMobileOrder> _allStores = []; // すべての店舗のリスト
  List<StoreMobileOrder> _filteredStores = []; // 検索結果の店舗リスト
  // 検索履歴保存
  List<StoreMobileOrder> _searchHistory = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();

  late FocusNode _storeNameFocusNode;
  Timer? _debounceTimer; // 検索debounce用タイマー

  @override
  void initState() {
    super.initState();
    _getStores();
    _loadSearchHistory();
    _storeNameFocusNode = FocusNode();

    // テキスト入力欄に対して自動でフォーカスを当てる
    if (!widget.isMainView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _storeNameFocusNode.requestFocus();
      });
    }

    // テキスト入力の変更を監視するリスナーを追加（debounce付き）
    _storeNameController.addListener(_onSearchTextChanged);
  }

  // 店舗情報を取得
  Future<void> _getStores() async {
    try {
      // 全店舗データを取得してStoreMobileOrderに変換
      final storeListJson = await cacheService.getData('stores');
      final List<StoreMobileOrder> allStores = storeListJson
          .map<StoreMobileOrder>((json) => StoreMobileOrder.fromJson(json))
          .toList();

      setState(() {
        _allStores = allStores;
        _filteredStores = []; // 初期状態では検索結果は空
      });
    } catch (e) {
      setState(() {});
      // エラー処理
      debugPrint('Error loading stores: $e');
    }
  }

  // 検索履歴を読み込み
  Future<void> _loadSearchHistory() async {
    try {
      final history = await _databaseHelper.getRecentSearchHistory();
      setState(() {
        _searchHistory = history;
        if (kDebugMode) {
          debugPrint(
            'Loaded search history: ${_searchHistory.map((store) => store.storeName).toList()}',
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  // テキスト入力変更時の処理（debounce付き）
  void _onSearchTextChanged() {
    // 既存のタイマーをキャンセル
    _debounceTimer?.cancel();

    // 新しいタイマーを設定（300ms後に検索実行）
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterStores();
    });
  }

  // 条件を満たす店舗をフィルタリング
  void _filterStores() {
    final String keyword = _storeNameController.text.toLowerCase();

    // キーワードが空の場合は検索結果をクリア
    if (keyword.isEmpty) {
      setState(() {
        _filteredStores = [];
      });
      return;
    }

    // 店舗名か住所に部分一致する店舗をフィルタリング
    final filtered = _allStores.where((store) {
      final bool matchesStoreName = store.storeName.toLowerCase().contains(keyword);
      final bool matchesAddress = store.address?.toLowerCase().contains(keyword) ?? false;
      return matchesStoreName || matchesAddress;
    }).toList();

    setState(() {
      _filteredStores = filtered;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // タイマーをキャンセル
    _storeNameController.removeListener(_onSearchTextChanged); // リスナーを削除
    _storeNameController.dispose();
    _storeNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐオプション
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => widget.backMain(),
          color: MyColors.headerLeadingIcon,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            _Header(
              formKey: _formKey,
              storeNameController: _storeNameController,
              storeNameFocusNode: _storeNameFocusNode,
            ),
            const SizedBox(height: 28),
            // 検索結果が空の場合は検索履歴を表示
            if (_storeNameController.text.isEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const MyCustomText(
                        text: '検索履歴',
                        fontSize: 14,
                        textColor: MyColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _searchHistory.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: MyCustomText(
                                text: '検索履歴がありません',
                                fontSize: 16,
                                textColor: MyColors.greyText,
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: _SearchHistory(
                                searchHistory: _searchHistory,
                                onHistoryTap: (query) {
                                  _storeNameController.text = query;
                                  _filterStores();
                                },
                                // onHistoryDelete: _deleteSearchHistoryItem,
                              ),
                            ),
                    ),
                  ],
                ),
              )
            else if (_filteredStores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const MyCustomText(text: '条件に一致する店舗が見つかりませんでした', fontSize: 16),
              )
            else
              // 検索結果リストの表示
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 5,
                    children: [
                      const MyCustomText(text: '候補', fontSize: 16, textColor: MyColors.greyText),
                      _StoreList(stores: _filteredStores, onValueSelected: widget.onValueSelected),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 店舗リストを表示するウィジェット
class _StoreList extends StatelessWidget {
  const _StoreList({required this.stores, required this.onValueSelected});
  final List<StoreMobileOrder> stores;
  final void Function(StoreMobileOrder) onValueSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: MyCustomText(text: store.storeName, fontSize: 16, fontWeight: FontWeight.bold),
            subtitle: store.address != null
                ? MyCustomText(text: store.address!, fontSize: 14, textColor: MyColors.greyText)
                : null,
            trailing: store.formattedDistanceKm != null
                ? MyCustomText(
                    text: store.formattedDistanceKm!,
                    fontSize: 14,
                    textColor: MyColors.greyText,
                  )
                : null,
            onTap: () {
              // ここで検索履歴に店舗名と住所を追加
              final databaseHelper = DatabaseHelper.instance;
              databaseHelper.saveSearchHistory(store);
              // 地図画面に戻る
              onValueSelected(store);
            },
          ),
        );
      },
    );
  }
}

// 検索履歴を表示するウィジェット
class _SearchHistory extends StatelessWidget {
  const _SearchHistory({required this.searchHistory, required this.onHistoryTap});

  final List<StoreMobileOrder> searchHistory;
  final void Function(String) onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: searchHistory.length,
      itemBuilder: (context, index) {
        final store = searchHistory[index];
        return ListTile(
          title: MyCustomText(text: store.storeName, fontSize: 24),
          subtitle: MyCustomText(
            text: store.address ?? '',
            fontSize: 16,
            textColor: MyColors.greyText,
          ),
          // onTap: () => onHistoryTap(storeName),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.formKey,
    required this.storeNameController,
    required this.storeNameFocusNode,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController storeNameController;
  final FocusNode storeNameFocusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3), // Shadow positioned only below the container
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              TextFormField(
                key: Key('store_name'),
                controller: storeNameController,
                focusNode: storeNameFocusNode,
                decoration: InputDecoration(
                  hintText: '店舗名・地名・住所',
                  hintStyle: const TextStyle(fontSize: 24, color: Colors.black54),
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: MyColors.loginFormField, width: 2),
                  ),
                ),
                cursorColor: MyColors.loginFormField,
                keyboardType: TextInputType.streetAddress,
                keyboardAppearance: Brightness.light,
                validator: (value) {
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
