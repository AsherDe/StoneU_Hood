// lib/features/community/community_controller.dart
import 'package:flutter/material.dart' hide MaterialType;
import 'models/marketplace_item.dart';
import 'models/study_material.dart';
import 'services/community_service.dart';
import '../calendar/models/event.dart';

class CommunityController extends ChangeNotifier {
  final CommunityService _service = CommunityService();
  
  // Marketplace Items
  List<MarketplaceItem> _marketplaceItems = [];
  List<MarketplaceItem> _featuredItems = [];
  List<String> _favoriteItemIds = [];
  bool _isLoadingItems = false;
  String? _itemSearchQuery;
  ItemCategory? _selectedCategory;
  
  // Study Materials
  List<StudyMaterial> _studyMaterials = [];
  List<StudyMaterial> _trendingMaterials = [];
  List<String> _favoriteMaterialIds = [];
  bool _isLoadingMaterials = false;
  String? _materialSearchQuery;
  StudyMaterialType? _selectedMaterialType;
  String? _selectedSubject;
  
  // User
  UserProfile? _currentUser;
  bool _isLoadingUser = false;
  
  // Chat
  List<ChatConversation> _conversations = [];
  Map<String, List<ChatMessage>> _messagesByConversation = {};
  bool _isLoadingChats = false;
  
  // Calendar
  List<CalendarEvent> _communityEvents = [];
  bool _isLoadingEvents = false;
  
  // Getters
  List<MarketplaceItem> get marketplaceItems => _marketplaceItems;
  List<MarketplaceItem> get featuredItems => _featuredItems;
  List<String> get favoriteItemIds => _favoriteItemIds;
  bool get isLoadingItems => _isLoadingItems;
  
  List<StudyMaterial> get studyMaterials => _studyMaterials;
  List<StudyMaterial> get trendingMaterials => _trendingMaterials;
  List<String> get favoriteMaterialIds => _favoriteMaterialIds;
  bool get isLoadingMaterials => _isLoadingMaterials;
  
  UserProfile? get currentUser => _currentUser;
  bool get isLoadingUser => _isLoadingUser;
  
  List<ChatConversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get messagesByConversation => _messagesByConversation;
  bool get isLoadingChats => _isLoadingChats;
  
  List<CalendarEvent> get communityEvents => _communityEvents;
  bool get isLoadingEvents => _isLoadingEvents;
  
  // Filtered Items
  List<MarketplaceItem> get filteredMarketplaceItems {
    return _marketplaceItems.where((item) {
      // Apply category filter
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      
      // Apply search filter
      if (_itemSearchQuery != null && _itemSearchQuery!.isNotEmpty) {
        return item.title.toLowerCase().contains(_itemSearchQuery!.toLowerCase()) ||
            item.description.toLowerCase().contains(_itemSearchQuery!.toLowerCase());
      }
      
      return true;
    }).toList();
  }
  
  List<StudyMaterial> get filteredStudyMaterials {
    return _studyMaterials.where((material) {
      // Apply material type filter
      if (_selectedMaterialType != null && material.materialType != _selectedMaterialType) {
        return false;
      }
      
      // Apply subject filter
      if (_selectedSubject != null && material.subject != _selectedSubject) {
        return false;
      }
      
      // Apply search filter
      if (_materialSearchQuery != null && _materialSearchQuery!.isNotEmpty) {
        return material.title.toLowerCase().contains(_materialSearchQuery!.toLowerCase()) ||
            material.description.toLowerCase().contains(_materialSearchQuery!.toLowerCase()) ||
            material.tags.any((tag) => tag.toLowerCase().contains(_materialSearchQuery!.toLowerCase()));
      }
      
      return true;
    }).toList();
  }
  
  // Filter setters
  void setItemSearchQuery(String? query) {
    _itemSearchQuery = query;
    notifyListeners();
  }
  
  void setSelectedCategory(ItemCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void setMaterialSearchQuery(String? query) {
    _materialSearchQuery = query;
    notifyListeners();
  }
  
  void setSelectedMaterialType(StudyMaterialType? type) {
    _selectedMaterialType = type;
    notifyListeners();
  }
  
  void setSelectedSubject(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }
  
  // Data loading methods
  Future<void> loadMarketplaceItems() async {
    _isLoadingItems = true;
    notifyListeners();
    
    try {
      final items = await _service.getMarketplaceItems();
      _marketplaceItems = items;
      _isLoadingItems = false;
      notifyListeners();
    } catch (e) {
      _isLoadingItems = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> loadFeaturedItems() async {
    try {
      final items = await _service.getFeaturedMarketplaceItems();
      _featuredItems = items;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<void> loadStudyMaterials() async {
    _isLoadingMaterials = true;
    notifyListeners();
    
    try {
      final materials = await _service.getStudyMaterials();
      _studyMaterials = materials;
      _isLoadingMaterials = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMaterials = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> loadTrendingMaterials() async {
    try {
      final materials = await _service.getTrendingStudyMaterials();
      _trendingMaterials = materials;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<void> loadFavorites() async {
    try {
      _favoriteItemIds = await _service.getFavoriteItemIds();
      _favoriteMaterialIds = await _service.getFavoriteMaterialIds();
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> toggleFavoriteItem(String itemId) async {
    try {
      final result = await _service.toggleFavoriteItem(itemId);
      if (result) {
        await loadFavorites();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> toggleFavoriteMaterial(String materialId) async {
    try {
      final result = await _service.toggleFavoriteMaterial(materialId);
      if (result) {
        await loadFavorites();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  // User methods
  Future<void> loadCurrentUser() async {
    _isLoadingUser = true;
    notifyListeners();
    
    try {
      _currentUser = await _service.getCurrentUser();
      _isLoadingUser = false;
      notifyListeners();
    } catch (e) {
      _isLoadingUser = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> login(String email, String password) async {
    _isLoadingUser = true;
    notifyListeners();
    
    try {
      final result = await _service.login(email, password);
      if (result) {
        await loadCurrentUser();
      }
      _isLoadingUser = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoadingUser = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> logout() async {
    try {
      final result = await _service.logout();
      if (result) {
        _currentUser = null;
        notifyListeners();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  // Chat methods
  Future<void> loadConversations() async {
    _isLoadingChats = true;
    notifyListeners();
    
    try {
      final conversations = await _service.getConversations();
      _conversations = conversations;
      _isLoadingChats = false;
      notifyListeners();
    } catch (e) {
      _isLoadingChats = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> loadMessages(String conversationId) async {
    try {
      final messages = await _service.getMessages(conversationId);
      _messagesByConversation[conversationId] = messages;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> sendMessage(String conversationId, String text) async {
    try {
      final result = await _service.sendMessage(conversationId, text);
      if (result) {
        // Reload messages to include the new one
        await loadMessages(conversationId);
        // Also reload conversations to update last message
        await loadConversations();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  // Calendar methods
  Future<void> loadCommunityEvents() async {
    _isLoadingEvents = true;
    notifyListeners();
    
    try {
      final events = await _service.getCommunityEvents();
      _communityEvents = events;
      _isLoadingEvents = false;
      notifyListeners();
    } catch (e) {
      _isLoadingEvents = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> addEventToCalendar(CalendarEvent event) async {
    try {
      return await _service.addEventToCalendar(event);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  // Item management methods
  Future<bool> createMarketplaceItem(MarketplaceItem item) async {
    try {
      final result = await _service.createMarketplaceItem(item);
      if (result) {
        // Reload items to include the new one
        await loadMarketplaceItems();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> updateMarketplaceItem(MarketplaceItem item) async {
    try {
      final result = await _service.updateMarketplaceItem(item);
      if (result) {
        // Reload items to include the updated one
        await loadMarketplaceItems();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> deleteMarketplaceItem(String itemId) async {
    try {
      final result = await _service.deleteMarketplaceItem(itemId);
      if (result) {
        // Reload items to remove the deleted one
        await loadMarketplaceItems();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> createStudyMaterial(StudyMaterial material) async {
    try {
      final result = await _service.createStudyMaterial(material);
      if (result) {
        // Reload materials to include the new one
        await loadStudyMaterials();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> updateStudyMaterial(StudyMaterial material) async {
    try {
      final result = await _service.updateStudyMaterial(material);
      if (result) {
        // Reload materials to include the updated one
        await loadStudyMaterials();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  Future<bool> deleteStudyMaterial(String materialId) async {
    try {
      final result = await _service.deleteStudyMaterial(materialId);
      if (result) {
        // Reload materials to remove the deleted one
        await loadStudyMaterials();
      }
      return result;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  
  // Initialize the controller - call this when the app starts
  Future<void> initialize() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _service.checkLoggedIn();
      if (isLoggedIn) {
        await loadCurrentUser();
      }
      
      // Load initial data
      await Future.wait([
        loadMarketplaceItems(),
        loadFeaturedItems(),
        loadStudyMaterials(),
        loadTrendingMaterials(),
        loadFavorites(),
        loadConversations(),
        loadCommunityEvents(),
      ]);
    } catch (e) {
      // Handle initialization error
      print('Failed to initialize community controller: $e');
    }
  }
}