import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fb_button.dart';
import '../../../core/widgets/fb_text_field.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../donations/domain/models/donation.dart';
import '../../donations/presentation/donation_provider.dart';
import 'widgets/gemini_food_scanner_card.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  DonationType _donationType = DonationType.food;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'meals');
  final _addressController = TextEditingController();
  final _allergenController = TextEditingController();

  // Food specific state
  bool _isVeg = true;
  String _storageCondition = 'ambient';
  DateTime _pickupDeadline = DateTime.now().add(const Duration(hours: 4));
  bool _safetyCharterAgreed = true;

  // Clothing specific state
  String _clothingCategory = 'winter';
  String _conditionGrade = 'like_new';
  bool _isWashedAndClean = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _titleController.text = 'Cooked Meals (Fresh Surplus)';
    _quantityController.text = '10';
    _unitController.text = 'meals';
    _descriptionController.text =
        'Freshly prepared wholesome food, hygienically packed in food containers.';
    if (auth.user?.address != null) {
      _addressController.text = auth.user!.address!;
    } else {
      _addressController.text = 'Powai Naka, Satara';
    }
    _safetyCharterAgreed = true;
    _isWashedAndClean = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _addressController.dispose();
    _allergenController.dispose();
    super.dispose();
  }

  Future<void> _selectPickupDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDeadline,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_pickupDeadline),
      );
      if (time != null && mounted) {
        setState(() {
          _pickupDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_donationType == DonationType.food && !_safetyCharterAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the Food Safety and Hygiene Charter.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final donationProvider = context.read<DonationProvider>();

    final double qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;

    final newDonation = Donation(
      id: 'dn-${DateTime.now().millisecondsSinceEpoch}',
      donorId: auth.user?.id ?? 'usr-donor-101',
      donorName: auth.user?.organizationName ?? auth.user?.fullName ?? 'FoodBridge Donor',
      donorPhone: auth.user?.phone ?? '+91 98200 12345',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: qty,
      unit: _unitController.text.trim(),
      type: _donationType,
      status: DonationStatus.listed,
      pickupAddress: _addressController.text.trim(),
      city: _addressController.text.toLowerCase().contains('pune')
          ? 'Pune'
          : (_addressController.text.toLowerCase().contains('mumbai') ? 'Mumbai' : 'Satara'),
      createdAt: DateTime.now(),
      pickupDeadline: _pickupDeadline,
      isVeg: _isVeg,
      prepTime: DateTime.now().subtract(const Duration(minutes: 30)),
      storageCondition: _storageCondition,
      allergenNotes: _allergenController.text.trim().isNotEmpty
          ? _allergenController.text.trim()
          : null,
      safetyCharterAgreed: _safetyCharterAgreed,
      clothingCategory: _donationType == DonationType.clothing ? _clothingCategory : null,
      conditionGrade: _donationType == DonationType.clothing ? _conditionGrade : null,
      isWashedAndClean: _isWashedAndClean,
    );

    final success = await donationProvider.createDonation(newDonation);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newDonation.type.displayName} donation listed successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(donationProvider.errorMessage ?? 'Failed to list donation.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('List a Donation'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Segmented Button: Food vs Clothing
              Center(
                child: SegmentedButton<DonationType>(
                  segments: const [
                    ButtonSegment(
                      value: DonationType.food,
                      label: Text('Food Surplus'),
                      icon: Icon(Icons.restaurant_rounded),
                    ),
                    ButtonSegment(
                      value: DonationType.clothing,
                      label: Text('Clothing'),
                      icon: Icon(Icons.checkroom_rounded),
                    ),
                  ],
                  selected: {_donationType},
                  onSelectionChanged: (set) {
                    setState(() {
                      _donationType = set.first;
                      _unitController.text =
                          _donationType == DonationType.food ? 'meals' : 'pieces';
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              if (_donationType == DonationType.food) ...[
                GeminiFoodScannerCard(
                  onScanComplete: (result, imagePath) {
                    setState(() {
                      _titleController.text = result.foodTitle;
                      _isVeg = result.isVeg;
                      _storageCondition = result.storageCondition;
                      _pickupDeadline = DateTime.now().add(Duration(hours: result.safeShelfLifeHours));
                      _descriptionController.text = '${result.marathiSummary}\n${result.safetyAdvisory}';
                      _safetyCharterAgreed = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gemini AI: ${result.foodTitle} स्कॅन यशस्वी!'),
                        backgroundColor: AppColors.primaryGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Title
              FBTextField(
                label: _donationType == DonationType.food
                    ? 'Food Item Title'
                    : 'Clothing Description',
                hint: _donationType == DonationType.food
                    ? 'e.g. 50 Veg Pulao & Raita Packets'
                    : 'e.g. Warm Blankets and Winter Jackets',
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              FBTextField(
                label: 'Details & Packaging',
                hint: _donationType == DonationType.food
                    ? 'State freshness, preparation details, and container type...'
                    : 'State item conditions, target sizes, and packing details...',
                controller: _descriptionController,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and Unit
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FBTextField(
                      label: 'Quantity',
                      hint: '50',
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || double.tryParse(val) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FBTextField(
                      label: 'Unit',
                      hint: _donationType == DonationType.food ? 'meals' : 'pieces',
                      controller: _unitController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category-Specific Fields
              if (_donationType == DonationType.food) ...[
                const Text(
                  'Food Quality & Dietary Specifications',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Pure Vegetarian'),
                      selected: _isVeg,
                      avatar: Icon(
                        Icons.eco_rounded,
                        color: _isVeg ? AppColors.primaryGreen : AppColors.mutedGrey,
                        size: 18,
                      ),
                      onSelected: (val) => setState(() => _isVeg = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Non-Vegetarian'),
                      selected: !_isVeg,
                      onSelected: (val) => setState(() => _isVeg = !val),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Storage / Holding Temperature:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Ambient Room Temp'),
                      selected: _storageCondition == 'ambient',
                      onSelected: (sel) {
                        if (sel) setState(() => _storageCondition = 'ambient');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Hot-Holding (>63°C)'),
                      selected: _storageCondition == 'hot',
                      onSelected: (sel) {
                        if (sel) setState(() => _storageCondition = 'hot');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Chilled / Refrigerated (<5°C)'),
                      selected: _storageCondition == 'chilled',
                      onSelected: (sel) {
                        if (sel) setState(() => _storageCondition = 'chilled');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                FBTextField(
                  label: 'Allergen / Ingredient Warnings (Optional)',
                  hint: 'e.g. Contains dairy, peanuts, mustard, gluten',
                  controller: _allergenController,
                ),
              ] else ...[
                // Clothing fields
                const Text(
                  'Clothing Category & Condition',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Winter / Warm Wear'),
                      selected: _clothingCategory == 'winter',
                      onSelected: (sel) {
                        if (sel) setState(() => _clothingCategory = 'winter');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Kids (Ages 0-14)'),
                      selected: _clothingCategory == 'kids',
                      onSelected: (sel) {
                        if (sel) setState(() => _clothingCategory = 'kids');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Blankets / Bedding'),
                      selected: _clothingCategory == 'blankets',
                      onSelected: (sel) {
                        if (sel) setState(() => _clothingCategory = 'blankets');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Adult General'),
                      selected: _clothingCategory == 'adults',
                      onSelected: (sel) {
                        if (sel) setState(() => _clothingCategory = 'adults');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Item Condition:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Brand New'),
                      selected: _conditionGrade == 'brand_new',
                      onSelected: (sel) {
                        if (sel) setState(() => _conditionGrade = 'brand_new');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Like New'),
                      selected: _conditionGrade == 'like_new',
                      onSelected: (sel) {
                        if (sel) setState(() => _conditionGrade = 'like_new');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Good Wearable'),
                      selected: _conditionGrade == 'good',
                      onSelected: (sel) {
                        if (sel) setState(() => _conditionGrade = 'good');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isWashedAndClean,
                  title: const Text(
                    'Items are washed, clean, and in wearable state',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (val) => setState(() => _isWashedAndClean = val ?? true),
                ),
              ],

              const SizedBox(height: 20),

              // Pickup Deadline
              const Text(
                'Mandatory Collection Deadline',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectPickupDeadline,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderGrey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateFormat.format(_pickupDeadline),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.edit_calendar_rounded, color: AppColors.mutedGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Address
              FBTextField(
                label: 'Pickup Address & Landmarks',
                hint: 'Shop / Apartment name, Street, Landmark',
                controller: _addressController,
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Address is required for volunteer navigation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Safety declaration
              if (_donationType == DonationType.food) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _safetyCharterAgreed,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) => setState(() => _safetyCharterAgreed = val ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'I declare that this food was prepared under hygienic conditions, has been kept safely, and is fit for human consumption according to FSSAI guidelines.',
                            style: TextStyle(fontSize: 12, color: AppColors.deepGreen, height: 1.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              FBButton(
                label: 'Publish Donation',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
