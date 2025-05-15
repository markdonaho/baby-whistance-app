import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart'; // Updated import
import 'package:baby_whistance_app/features/guesses/application/guess_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp
import 'package:baby_whistance_app/features/guesses/domain/guess_model.dart'; // Import Guess model
import 'package:intl/intl.dart'; // For date formatting

// Define the fixed birth date
final DateTime fixedBirthDate = DateTime(2025, 11, 21);

// Options for Dropdowns
const List<String> hairColorOptions = ["Brown", "Blonde", "Black", "Red", "Auburn", "None/Bald"];
const List<String> eyeColorOptions = ["Brown", "Blue", "Green", "Hazel", "Grey", "Super Hero Lasers"];
const List<String> looksLikeOptions = ["Mom", "Dad", "Both", "Neither"];
const List<String> brycenReactionOptions = ["Passes out", "Pukes", "Makes it through fine"];

// Weight options
final List<int> poundOptions = List<int>.generate(12, (i) => i + 4); // 4 to 15 lbs
final List<int> ounceOptions = List<int>.generate(16, (i) => i);    // 0 to 15 oz
final List<int> inchOptions = List<int>.generate(11, (i) => i + 15); // 15 to 25 inches

// Helper to format total ounces to lbs and oz string
String formatWeight(int? totalOunces) {
  if (totalOunces == null || totalOunces <= 0) return "Not set";
  final int pounds = totalOunces ~/ 16;
  final int ounces = totalOunces % 16;
  return "$pounds lbs $ounces oz";
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the guess submission state for global feedback if needed
    ref.listen<AsyncValue<void>>(
      guessControllerProvider, 
      (_, state) {
        if (state is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error.toString())),
          );
        }
        // Optionally handle AsyncLoading or AsyncData for global messages
      }
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Submit Your Guess!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // For better card width
            children: <Widget>[
              Text(
                'Welcome! Baby boy is due ${DateFormat('MMMM d, yyyy').format(fixedBirthDate)}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Make your predictions below:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const GuessSubmissionForm(),
              const SizedBox(height: 40),
              const Text('Your Most Recent Guess:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, child) {
                  final guessesAsyncValue = ref.watch(userGuessesStreamProvider);
                  return guessesAsyncValue.when(
                    data: (guesses) {
                      if (guesses.isEmpty) {
                        return const Text('No guess submitted yet.', textAlign: TextAlign.center,);
                      }
                      final mostRecentGuess = guesses.first;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target Date: ${DateFormat('MMMM d, yyyy').format(mostRecentGuess.dateGuess.toDate())},', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Time: ${mostRecentGuess.timeGuess}', style: const TextStyle(fontSize: 15)),
                              Text('Weight: ${formatWeight(mostRecentGuess.weightGuess)}', style: const TextStyle(fontSize: 15)),
                              Text('Length: ${mostRecentGuess.lengthGuess} inches', style: const TextStyle(fontSize: 15)),
                              Text('Hair Color: ${mostRecentGuess.hairColorGuess}', style: const TextStyle(fontSize: 15)),
                              Text('Eye Color: ${mostRecentGuess.eyeColorGuess}', style: const TextStyle(fontSize: 15)),
                              Text('Looks Like: ${mostRecentGuess.looksLikeGuess}', style: const TextStyle(fontSize: 15)),
                              if (mostRecentGuess.brycenReactionGuess != null && mostRecentGuess.brycenReactionGuess!.isNotEmpty)
                                Text('Brycen\'s Reaction: ${mostRecentGuess.brycenReactionGuess}', style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 8),
                              Text('Submitted: ${DateFormat('MMM d, yyyy HH:mm').format(mostRecentGuess.submittedAt.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error fetching guess: ${err.toString()}', textAlign: TextAlign.center,),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuessSubmissionForm extends ConsumerStatefulWidget {
  const GuessSubmissionForm({super.key});

  @override
  ConsumerState<GuessSubmissionForm> createState() => _GuessSubmissionFormState();
}

class _GuessSubmissionFormState extends ConsumerState<GuessSubmissionForm> {
  final _formKey = GlobalKey<FormState>();

  final _timeController = TextEditingController();
  String? _hairColorValue;
  String? _eyeColorValue;
  String? _looksLikeValue;
  String? _brycenReactionValue;
  int? _selectedPounds;
  int? _selectedOunces;
  int? _selectedInches; // For length
  bool _isEditingWeight = false;

  Guess? _existingGuess; // To store the existing guess if any
  bool _isFormPopulatedFromGuess = false; // To prevent re-populating on every rebuild

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // It's better to listen or use a Consumer in build for Riverpod
  }
  
  void _populateFormFromGuess(Guess guess) {
    _timeController.text = guess.timeGuess;
    if (guess.weightGuess != null) {
      _selectedPounds = guess.weightGuess! ~/ 16;
      _selectedOunces = guess.weightGuess! % 16;
    } else {
      _selectedPounds = null;
      _selectedOunces = null;
    }
    _selectedInches = guess.lengthGuess;
    _hairColorValue = guess.hairColorGuess;
    _eyeColorValue = guess.eyeColorGuess;
    _looksLikeValue = guess.looksLikeGuess;
    _brycenReactionValue = guess.brycenReactionGuess;
    _isEditingWeight = false; // Reset weight editing state
  }

  void _resetFormFields() {
    _formKey.currentState?.reset();
    _timeController.clear();
    _hairColorValue = null;
    _eyeColorValue = null;
    _looksLikeValue = null;
    _brycenReactionValue = null;
    _selectedPounds = null;
    _selectedOunces = null;
    _selectedInches = null;
    _isEditingWeight = false;
    _existingGuess = null; 
    _isFormPopulatedFromGuess = false;
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final String formattedTime = 
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _handleSaveGuess() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPounds == null || _selectedOunces == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select weight (pounds and ounces).')),
          );
        }
        return;
      }
      if (_selectedInches == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select length in inches.')),
          );
        }
        return;
      }
      if (_hairColorValue == null || _eyeColorValue == null || _looksLikeValue == null) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please make a selection for all dropdown fields (except Brycen's reaction).")),
            );
        }
        return;
      }

      setState(() { _isLoading = true; });

      final dateGuess = Timestamp.fromDate(fixedBirthDate);
      final int totalOunces = (_selectedPounds! * 16) + _selectedOunces!;
      final int totalInches = _selectedInches!;
      bool success = false;

      if (_existingGuess != null && _existingGuess!.id != null) {
        // Update existing guess
        success = await ref.read(guessControllerProvider.notifier).updateGuess(
          guessId: _existingGuess!.id!,
          dateGuess: dateGuess, // date is fixed, so it\'s the same
          timeGuess: _timeController.text,
          weightGuess: totalOunces,
          lengthGuess: totalInches,
          hairColorGuess: _hairColorValue!,
          eyeColorGuess: _eyeColorValue!,
          looksLikeGuess: _looksLikeValue!,
          brycenReactionGuess: _brycenReactionValue,
        );
      } else {
        // Submit new guess
        success = await ref.read(guessControllerProvider.notifier).submitGuess(
          dateGuess: dateGuess,
          timeGuess: _timeController.text,
          weightGuess: totalOunces,
          lengthGuess: totalInches,
          hairColorGuess: _hairColorValue!,
          eyeColorGuess: _eyeColorValue!,
          looksLikeGuess: _looksLikeValue!,
          brycenReactionGuess: _brycenReactionValue,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_existingGuess != null ? 'Guess updated successfully!' : 'Guess submitted successfully!')),
          );
          // Don't reset form on successful update, user might want to see their saved values
          // If it was a new submission, we can clear.
          // For now, let\'s be consistent and not auto-clear/reset.
          // User can navigate away or app can redirect.
          // _resetFormFields(); // Decided against auto-resetting for now.
          // If staying on the form, ensure _existingGuess is updated with new submittedAt if that changed.
          // This might require re-fetching or getting the updated guess back.
          // For simplicity, current data in form is the "latest".
          
        } else {
          final errorState = ref.read(guessControllerProvider);
          if (errorState is! AsyncError) { // If it\'s already an AsyncError, the global listener in HomeScreen handles it.
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_existingGuess != null ? 'Failed to update guess. Please try again.' : 'Failed to submit guess. Please try again.')),
             );
          }
        }
        setState(() { _isLoading = false; });
      }
    }
  }

  Widget _buildIntDropdown(String label, int? currentValue, List<int> items, ValueChanged<int?> onChanged, {String? unit}) {
    return DropdownButtonFormField<int>(
      value: currentValue,
      decoration: InputDecoration(labelText: label + (unit != null ? " ($unit)" : ""), hintText: "Select"),
      isExpanded: true,
      items: items.map((int value) => DropdownMenuItem<int>(value: value, child: Text(value.toString()))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select' : null,
    );
  }

  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged, {bool isOptional = false}) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(labelText: label, hintText: isOptional ? 'Select (optional)' : 'Select'),
      isExpanded: true,
      items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
      onChanged: onChanged,
      validator: (value) => !isOptional && value == null ? 'Please select' : null,
    );
  }

  Widget _buildWeightInput() {
    if (_isEditingWeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildIntDropdown("Weight", _selectedPounds, poundOptions, (val) => setState(() => _selectedPounds = val), unit: "lbs")),
              const SizedBox(width: 12),
              Expanded(child: _buildIntDropdown("", _selectedOunces, ounceOptions, (val) => setState(() => _selectedOunces = val), unit: "oz")),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: const Text("Done"),
              onPressed: () {
                if (_selectedPounds != null && _selectedOunces != null) {
                  setState(() => _isEditingWeight = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both pounds and ounces.')));
                }
              },
            ),
          )
        ],
      );
    } else {
      return InputDecorator(
          decoration: InputDecoration(
            labelText: "Weight Guess",
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0), // Adjust padding to align better
          ),
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50,30), alignment: Alignment.centerLeft),
            child: Text(formatWeight((_selectedPounds ?? 0) * 16 + (_selectedOunces ?? 0)), style: Theme.of(context).textTheme.titleMedium),
            onPressed: () => setState(() => _isEditingWeight = true),
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for existing guesses
    final userGuessesAsync = ref.watch(userGuessesStreamProvider);

    userGuessesAsync.whenData((guesses) {
      if (guesses.isNotEmpty) {
        final currentGuess = guesses.first;
        // If _existingGuess is null or different from currentGuess, populate the form.
        // Use a flag to ensure this happens only once after the guess is loaded,
        // or if the guess changes (e.g. submitted elsewhere and stream updates).
        if (!_isFormPopulatedFromGuess || (_existingGuess != null && _existingGuess!.id != currentGuess.id)) {
           // Check if widget is still mounted and frame is ready
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Check mounted again inside callback
                setState(() {
                  _existingGuess = currentGuess;
                  _populateFormFromGuess(currentGuess);
                  _isFormPopulatedFromGuess = true; 
                });
              }
            });
          }
        }
      } else {
        // No guess exists, if form was populated, clear it.
        if (_isFormPopulatedFromGuess && mounted) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                 _resetFormFields(); // Clear form if guess was deleted/became empty
              });
            }
           });
        }
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _timeController,
            decoration: InputDecoration(
              labelText: 'Time of Birth Guess',
              hintText: 'HH:MM (24-hour format)',
               suffixIcon: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context),
              ),
            ),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a time';
              }
              if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
                 return 'Please use HH:MM format';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildWeightInput(),
          const SizedBox(height: 12),
          _buildIntDropdown("Length", _selectedInches, inchOptions, (val) => setState(() => _selectedInches = val), unit: "inches"),
          const SizedBox(height: 12),
          _buildDropdown("Hair Color Guess", _hairColorValue, hairColorOptions, (val) => setState(() => _hairColorValue = val)),
          const SizedBox(height: 12),
          _buildDropdown("Eye Color Guess", _eyeColorValue, eyeColorOptions, (val) => setState(() => _eyeColorValue = val)),
          const SizedBox(height: 12),
          _buildDropdown("Who will baby look like?", _looksLikeValue, looksLikeOptions, (val) => setState(() => _looksLikeValue = val)),
          const SizedBox(height: 12),
          _buildDropdown("Brycen's Reaction (Dad)", _brycenReactionValue, brycenReactionOptions, (val) => setState(() => _brycenReactionValue = val), isOptional: true),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSaveGuess,
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_existingGuess != null ? 'Update Guess' : 'Submit Guess'),
            ),
          ),
        ],
      ),
    );
  }
} 