import 'package:baby_whistance_app/features/app_status/app_status_service.dart';
import 'package:baby_whistance_app/screens/guess_submission_edit_screen.dart' show hairColorOptions, eyeColorOptions, poundOptions, ounceOptions, inchOptions; // Reusing options
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';

class AdminEnterBabyDetailsScreen extends ConsumerStatefulWidget { // Changed to StatefulWidget
  const AdminEnterBabyDetailsScreen({super.key});

  @override
  ConsumerState<AdminEnterBabyDetailsScreen> createState() => _AdminEnterBabyDetailsScreenState();
}

class _AdminEnterBabyDetailsScreenState extends ConsumerState<AdminEnterBabyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  String? _hairColorValue;
  String? _eyeColorValue;
  int? _selectedPounds;
  int? _selectedOunces;
  int? _selectedInches;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Potentially load existing details if they exist
    final currentDetails = ref.read(currentAppStatusProvider).asData?.value?.actualBabyDetails;
    if (currentDetails != null) {
      _timeController.text = currentDetails['timeOfBirth'] ?? '';
      _selectedPounds = currentDetails['weightPounds'];
      _selectedOunces = currentDetails['weightOunces'];
      _selectedInches = currentDetails['lengthInches'];
      _hairColorValue = currentDetails['hairColor'];
      _eyeColorValue = currentDetails['eyeColor'];
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Or false based on preference
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final String formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _handleSaveDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPounds == null || _selectedOunces == null || _selectedInches == null || _hairColorValue == null || _eyeColorValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        return;
      }

      setState(() { _isLoading = true; });

      final details = {
        'timeOfBirth': _timeController.text,
        'weightPounds': _selectedPounds,
        'weightOunces': _selectedOunces,
        'lengthInches': _selectedInches,
        'hairColor': _hairColorValue,
        'eyeColor': _eyeColorValue,
      };

      try {
        await ref.read(appStatusServiceProvider.notifier).setActualBabyDetails(details);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Actual baby details saved!')),
          );
          // Optionally navigate back or clear form
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save details: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }
  
  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      isExpanded: true,
      items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select' : null,
    );
  }

  Widget _buildIntDropdown(String label, int? currentValue, List<int> items, ValueChanged<int?> onChanged, {String? unit}) {
    return DropdownButtonFormField<int>(
      value: currentValue,
      decoration: InputDecoration(labelText: label + (unit != null ? " ($unit)" : ""), border: const OutlineInputBorder()),
      isExpanded: true,
      items: items.map((int value) => DropdownMenuItem<int>(value: value, child: Text(value.toString()))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select' : null,
    );
  }


  @override
  Widget build(BuildContext context) {
    // Pre-fill form if details already exist - This is better done in initState or a separate provider.
    // For simplicity here, we'll rely on initState, but a more robust solution might listen to currentAppStatusProvider.

    return AppScaffold(
      title: 'Enter Actual Baby Details',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Enter the official baby statistics after arrival.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time of Birth',
                  hintText: 'HH:MM',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selectTime(context),
                  ),
                ),
                readOnly: true, // Time is selected via picker
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a time';
                  if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) return 'Invalid time format (HH:MM)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildIntDropdown("Weight (lbs)", _selectedPounds, poundOptions, (val) => setState(() => _selectedPounds = val))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildIntDropdown("Weight (oz)", _selectedOunces, ounceOptions, (val) => setState(() => _selectedOunces = val))),
                ],
              ),
              const SizedBox(height: 16),
               _buildIntDropdown("Length", _selectedInches, inchOptions, (val) => setState(() => _selectedInches = val), unit: "inches"),
              const SizedBox(height: 16),
              _buildDropdown("Hair Color", _hairColorValue, hairColorOptions, (val) => setState(() => _hairColorValue = val)),
              const SizedBox(height: 16),
              _buildDropdown("Eye Color", _eyeColorValue, eyeColorOptions, (val) => setState(() => _eyeColorValue = val)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSaveDetails,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
                child: _isLoading ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) : const Text('Save Actual Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }
} 