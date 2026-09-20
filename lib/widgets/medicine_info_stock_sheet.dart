import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import 'medicine_visual.dart';

class MedicineInfoStockSheet extends StatefulWidget {
  final Medicine medicine;

  const MedicineInfoStockSheet({super.key, required this.medicine});

  static Future<void> show(BuildContext context, Medicine medicine) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicineInfoStockSheet(medicine: medicine),
    );
  }

  @override
  State<MedicineInfoStockSheet> createState() => _MedicineInfoStockSheetState();
}

class _MedicineInfoStockSheetState extends State<MedicineInfoStockSheet> {
  late int _stock;
  late int _threshold;
  late String _unit;
  String? _photoPath;
  DateTime? _expiryDate;
  late TextEditingController _notesController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _stock = widget.medicine.currentStock;
    _threshold = widget.medicine.refillThreshold;
    _unit = widget.medicine.displayUnit;
    _photoPath = widget.medicine.photoPath;
    _expiryDate = widget.medicine.expiryDate;
    _notesController = TextEditingController(text: widget.medicine.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _photoPath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primaryTeal),
                title: Text('Take Photo with Camera', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.accentCyan),
                title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                  title: Text('Remove Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.accentRose)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 180)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveUpdates() async {
    final provider = context.read<MedicineProvider>();
    final updated = widget.medicine.copyWith(
      currentStock: _stock,
      refillThreshold: _threshold,
      unit: _unit,
      photoPath: _photoPath,
      expiryDate: _expiryDate,
      notes: _notesController.text.trim(),
    );

    final reminders = provider.getRemindersForMedicine(widget.medicine.id);
    await provider.updateMedicine(medicine: updated, reminders: reminders);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${widget.medicine.name} info updated successfully!',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.accentEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableUnits = widget.medicine.type.availableUnits;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: MedicineVisual.fromMedicine(widget.medicine, size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.medicine.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.medicine.dosage} • ${widget.medicine.type.label}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // 1. Medicine Strip / Box Photo Card
                  _buildSectionCard(
                    isDark: isDark,
                    title: 'Medicine Packaging / Strip Photo',
                    icon: Icons.photo_camera_rounded,
                    iconColor: AppColors.primaryTealLight,
                    child: Column(
                      children: [
                        if (_photoPath != null && File(_photoPath!).existsSync()) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_photoPath!),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                    onPressed: _showImageSourcePicker,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          InkWell(
                            onTap: _showImageSourcePicker,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primaryTeal, size: 28),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Add Strip or Box Photo (Optional)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Identify medicine easily by its real box or strip picture',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Stock & Inventory Management
                  _buildSectionCard(
                    isDark: isDark,
                    title: 'Stock & Inventory',
                    icon: Icons.inventory_2_rounded,
                    iconColor: AppColors.accentEmerald,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            // Unit selector chip
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: availableUnits.contains(_unit) ? _unit : availableUnits.first,
                                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryTealLight,
                                ),
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryTealLight),
                                items: availableUnits.map((u) {
                                  return DropdownMenuItem(value: u, child: Text(u));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _unit = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Interactive Counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, size: 28),
                                color: _stock > 0 ? AppColors.accentRose : Colors.grey,
                                onPressed: _stock > 0 ? () => setState(() => _stock--) : null,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_stock',
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: _stock <= _threshold
                                          ? (_stock <= 0 ? AppColors.accentRose : AppColors.accentAmber)
                                          : AppColors.accentEmerald,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _unit,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                                color: AppColors.accentEmerald,
                                onPressed: () => setState(() => _stock++),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Quick Refill Chips
                        Row(
                          children: [
                            Text(
                              'Quick Refill: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ...[5, 10, 30].map((add) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text('+$add'),
                                  labelStyle: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryTealLight,
                                  ),
                                  backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.12),
                                  side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.25)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onPressed: () => setState(() => _stock += add),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Expiry Date & Shelf Life Tracker
                  _buildSectionCard(
                    isDark: isDark,
                    title: 'Medicine Expiry Date',
                    icon: Icons.event_available_rounded,
                    iconColor: AppColors.accentAmber,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _expiryDate != null
                                      ? DateFormat('d MMMM yyyy').format(_expiryDate!)
                                      : 'No expiry date set',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                if (_expiryDate != null) ...[
                                  const SizedBox(height: 2),
                                  Builder(builder: (ctx) {
                                    final diffDays = _expiryDate!.difference(DateTime.now()).inDays;
                                    Color badgeColor;
                                    String badgeText;
                                    if (diffDays < 0) {
                                      badgeColor = AppColors.accentRose;
                                      badgeText = 'Expired (${-diffDays} days ago)';
                                    } else if (diffDays <= 30) {
                                      badgeColor = AppColors.accentAmber;
                                      badgeText = 'Expiring soon ($diffDays days left)';
                                    } else {
                                      badgeColor = AppColors.accentEmerald;
                                      badgeText = 'Safe to use ($diffDays days left)';
                                    }
                                    return Text(
                                      badgeText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: badgeColor,
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _pickExpiryDate,
                                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                                  label: Text(_expiryDate != null ? 'Change' : 'Set Date'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryTealLight,
                                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (_expiryDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                    tooltip: 'Clear expiry date',
                                    onPressed: () => setState(() => _expiryDate = null),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Doctor's Note & Advice
                  _buildSectionCard(
                    isDark: isDark,
                    title: "Doctor's Note & Special Instructions",
                    icon: Icons.note_alt_rounded,
                    iconColor: AppColors.accentCyan,
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Take after heavy breakfast, do not drink milk within 1 hour...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _saveUpdates,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Save & Update Info',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
