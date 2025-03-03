// lib/features/community/screens/create_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/marketplace_item.dart';
import '../community_controller.dart';
import 'package:provider/provider.dart';

class CreateItemScreen extends StatefulWidget {
  final MarketplaceItem? itemToEdit;

  const CreateItemScreen({
    Key? key,
    this.itemToEdit,
  }) : super(key: key);

  @override
  _CreateItemScreenState createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _tradeLinkController = TextEditingController();
  
  ItemCategory _selectedCategory = ItemCategory.other;
  ItemCondition _selectedCondition = ItemCondition.good;
  List<String> _imageUrls = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // If editing an existing item, populate the form
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _descriptionController.text = widget.itemToEdit!.description;
      _priceController.text = widget.itemToEdit!.price.toString();
      _tradeLinkController.text = widget.itemToEdit!.tradeLink ?? '';
      _selectedCategory = widget.itemToEdit!.category;
      _selectedCondition = widget.itemToEdit!.condition;
      _imageUrls = List.from(widget.itemToEdit!.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tradeLinkController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final controller = Provider.of<CommunityController>(context, listen: false);
      final currentUser = controller.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请先登录')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      if (widget.itemToEdit == null) {
        // Create new item
        final newItem = MarketplaceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          sellerName: currentUser.name,
          sellerContact: currentUser.email,
          tradeLink: _tradeLinkController.text.isEmpty ? null : _tradeLinkController.text,
          imageUrls: _imageUrls,
          createdAt: DateTime.now(),
          category: _selectedCategory,
          condition: _selectedCondition,
        );
        
        final success = await controller.createMarketplaceItem(newItem);
        
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败，请重试')),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      } else {
        // Update existing item
        final updatedItem = MarketplaceItem(
          id: widget.itemToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          sellerName: widget.itemToEdit!.sellerName,
          sellerContact: widget.itemToEdit!.sellerContact,
          tradeLink: _tradeLinkController.text.isEmpty ? null : _tradeLinkController.text,
          imageUrls: _imageUrls,
          createdAt: widget.itemToEdit!.createdAt,
          category: _selectedCategory,
          condition: _selectedCondition,
        );
        
        final success = await controller.updateMarketplaceItem(updatedItem);
        
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败，请重试')),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发生错误: $e')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _addImage() {
    // In a real app, this would launch an image picker
    // For now, we'll just add a placeholder
    setState(() {
      _imageUrls.add('https://via.placeholder.com/150');
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemToEdit == null ? '发布物品' : '编辑物品',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Image section
            _buildImageSection(),
            SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
                helperText: '简短描述您要出售的物品',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Price
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: '价格 (¥)',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入价格';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return '请输入有效的价格';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<ItemCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: '类别',
                border: OutlineInputBorder(),
              ),
              items: ItemCategory.values.map((category) {
                return DropdownMenuItem<ItemCategory>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            
            // Condition
            DropdownButtonFormField<ItemCondition>(
              value: _selectedCondition,
              decoration: InputDecoration(
                labelText: '物品状况',
                border: OutlineInputBorder(),
              ),
              items: ItemCondition.values.map((condition) {
                return DropdownMenuItem<ItemCondition>(
                  value: condition,
                  child: Text(condition.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCondition = value;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
                helperText: '详细描述物品的情况、使用年限、是否有损坏等',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入描述';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Trade link (optional)
            TextFormField(
              controller: _tradeLinkController,
              decoration: InputDecoration(
                labelText: '交易链接 (可选)',
                border: OutlineInputBorder(),
                helperText: '如果您有淘宝、闲鱼等平台的交易链接，可以在这里填写',
              ),
            ),
            SizedBox(height: 32),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: _isSubmitting
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        widget.itemToEdit == null ? '发布' : '保存',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '图片',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add image button
              GestureDetector(
                onTap: _addImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              
              // Image previews
              ..._imageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (_imageUrls.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '请至少添加一张图片',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}