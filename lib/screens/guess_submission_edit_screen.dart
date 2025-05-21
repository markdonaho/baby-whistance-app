import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/features/guesses/application/guess_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_whistance_app/features/guesses/domain/guess_model.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:baby_whistance_app/features/app_status/app_status_service.dart';

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

class GuessSubmissionEditScreen extends ConsumerWidget { // Renamed class
  const GuessSubmissionEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStatusAsync = ref.watch(currentAppStatusProvider);

    // Listen to the guess submission state for global feedback if needed
    ref.listen<AsyncValue<void>>(
      guessControllerProvider, 
      (_, state) {
        if (state is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error.toString())),
          );
        }
      }
    );

    // Check if we are in "edit mode" from query parameters
    final String? editMode = GoRouterState.of(context).uri.queryParameters['edit'];

    // Listen to user's guesses to potentially redirect
    ref.listen<AsyncValue<List<Guess>>>(
      userGuessesStreamProvider,
      (previous, next) {
        next.when(
          data: (guesses) {
            final currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
            // Only redirect if on this screen, guesses are present, AND not in edit mode
            if (currentLocation == '/guess-form' && guesses.isNotEmpty && editMode != 'true') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ModalRoute.of(context)?.isCurrent ?? false) {
                   context.goNamed(AppRoute.allGuesses.name);
                }
              });
            }
          },
          loading: () {},
          error: (err, stack) {},
        );
      },
    );

    final userGuessesAsync = ref.watch(userGuessesStreamProvider);
    if (userGuessesAsync is AsyncLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userGuessesAsync is AsyncError) {
      return AppScaffold(
        title: 'Error',
        body: Center(child: Text('Error loading guesses: ${userGuessesAsync.error}')),
        showBottomNavBar: true,
      );
    }

    return appStatusAsync.when(
      data: (appStatus) {
        final bool guessingAllowed = appStatus.guessingStatus == GuessingStatus.open;
        String noticeMessage = '';
        if (appStatus.guessingStatus == GuessingStatus.closed) {
          noticeMessage = 'Guessing is currently closed.';
        } else if (appStatus.guessingStatus == GuessingStatus.revealed) {
          noticeMessage = 'The baby details have been revealed! Guessing is closed.';
        }

        final Widget screenBody = Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                if (!guessingAllowed) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        noticeMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                GuessSubmissionForm(guessingAllowed: guessingAllowed), // Pass guessingAllowed
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
                        String formattedTimeGuess = mostRecentGuess.timeGuess;
                        try {
                          final hour = int.parse(mostRecentGuess.timeGuess.split(':')[0]);
                          final minute = int.parse(mostRecentGuess.timeGuess.split(':')[1]);
                          final dateTime = DateTime(2000, 1, 1, hour, minute); // Dummy date
                          formattedTimeGuess = DateFormat('h:mm a').format(dateTime);
                        } catch (e) {
                          print('Error formatting time guess on GuessSubmissionEditScreen: ${mostRecentGuess.timeGuess} - $e');
                        }

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
                                Text('Time: $formattedTimeGuess', style: const TextStyle(fontSize: 15)),
                                Text('Weight: ${formatWeight(mostRecentGuess.weightGuess)}', style: const TextStyle(fontSize: 15)),
                                Text('Length: ${mostRecentGuess.lengthGuess} inches', style: const TextStyle(fontSize: 15)),
                                Text('Hair Color: ${mostRecentGuess.hairColorGuess}', style: const TextStyle(fontSize: 15)),
                                Text('Eye Color: ${mostRecentGuess.eyeColorGuess}', style: const TextStyle(fontSize: 15)),
                                Text('Looks Like: ${mostRecentGuess.looksLikeGuess}', style: const TextStyle(fontSize: 15)),
                                if (mostRecentGuess.brycenReactionGuess != null && mostRecentGuess.brycenReactionGuess!.isNotEmpty)
                                  Text('Brycen\'s Reaction: ${mostRecentGuess.brycenReactionGuess}', style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 8),
                                Text('Submitted: ${DateFormat('MMM d, yyyy HH:mm').format(mostRecentGuess.submittedAt.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (mostRecentGuess.lastEditedAt != null)
                                  Text('Last Edited: ${DateFormat('MMM d, yyyy HH:mm').format(mostRecentGuess.lastEditedAt!.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        );

        return AppScaffold(
          title: 'Submit/Edit Your Guess',
          body: screenBody,
          showBottomNavBar: true, 
        );
      },
      loading: () => const AppScaffold(
        title: 'Submit/Edit Your Guess',
        body: Center(child: CircularProgressIndicator()),
        showBottomNavBar: true,
      ),
      error: (err, stack) => AppScaffold(
        title: 'Error Loading Status',
        body: Center(child: Text('Error loading app status: ${err.toString()}')),
        showBottomNavBar: true,
      ),
    );
  }
}

class GuessSubmissionForm extends ConsumerStatefulWidget {
  final bool guessingAllowed;
  const GuessSubmissionForm({super.key, required this.guessingAllowed});

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
  int? _selectedInches;
  bool _isEditingWeight = false;

  Guess? _existingGuess;
  bool _isFormPopulatedFromGuess = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    _isEditingWeight = false;
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
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _timeController.text = DateFormat('h:mm a').format(dt);
      });
    }
  }

  Future<void> _handleSaveGuess() async {
    if (!widget.guessingAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guessing is currently not open.')),
      );
      return;
    }

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
            const SnackBar(content: Text("Please make a selection for all dropdown fields (except Brycen\'s reaction).")),
            );
        }
        return;
      }

      setState(() { _isLoading = true; });

      final dateGuess = Timestamp.fromDate(fixedBirthDate);
      final int totalOunces = (_selectedPounds! * 16) + _selectedOunces!;
      final int totalInches = _selectedInches!;
      bool success = false;
      final bool wasEditing = _existingGuess != null && _existingGuess!.id != null; // Store if it was an edit

      final guessNotifier = ref.read(guessControllerProvider.notifier);

      // Convert display time (h:mm a) back to HH:mm for storage
      String timeToStore = _timeController.text;
      if (_timeController.text.isNotEmpty) {
        try {
          final parsedTime = DateFormat('h:mm a').parse(_timeController.text);
          timeToStore = DateFormat('HH:mm').format(parsedTime);
        } catch (e) {
          // Should not happen if validator works, but good to have a fallback
          print('Error parsing time for storage: ${_timeController.text} - $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid time format. Please re-select the time.')),
            );
            setState(() { _isLoading = false; });
          }
          return;
        }
      }

      if (wasEditing) { // Use the stored boolean
        success = await guessNotifier.updateGuess(
          guessId: _existingGuess!.id!,
          originalSubmittedAt: _existingGuess!.submittedAt,
          dateGuess: dateGuess, 
          timeGuess: timeToStore,
          weightGuess: totalOunces,
          lengthGuess: totalInches,
          hairColorGuess: _hairColorValue!,
          eyeColorGuess: _eyeColorValue!,
          looksLikeGuess: _looksLikeValue!,
          brycenReactionGuess: _brycenReactionValue,
        );
      } else {
        success = await guessNotifier.submitGuess(
          dateGuess: dateGuess,
          timeGuess: timeToStore,
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
            SnackBar(content: Text(wasEditing ? 'Guess updated successfully!' : 'Guess submitted successfully!')),
          );
          if (wasEditing) {
            // Navigate back to AllGuessesScreen only if it was an edit
            context.goNamed(AppRoute.allGuesses.name);
          }
        } else {
          final errorState = ref.read(guessControllerProvider);
          if (errorState is! AsyncError) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(wasEditing ? 'Failed to update guess. Please try again.' : 'Failed to submit guess. Please try again.')),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
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
    final userGuessesAsync = ref.watch(userGuessesStreamProvider);

    userGuessesAsync.whenData((guesses) {
      if (guesses.isNotEmpty) {
        final currentGuess = guesses.first;
        if (!_isFormPopulatedFromGuess || (_existingGuess != null && _existingGuess!.id != currentGuess.id)) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
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
        if (_isFormPopulatedFromGuess && mounted) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                 _resetFormFields();
              });
            }
           });
        }
      }
    });

    return AbsorbPointer(
      absorbing: !widget.guessingAllowed,
      child: Opacity(
        opacity: widget.guessingAllowed ? 1.0 : 0.5,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time of Birth Guess',
                  hintText: 'Select time (e.g. 10:30 AM)',
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
                  if (!RegExp(r'^\d{1,2}:\d{2} (AM|PM)$').hasMatch(value)) {
                     return 'Please select a valid time';
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
              _buildDropdown("Brycen\'s Reaction (Dad)", _brycenReactionValue, brycenReactionOptions, (val) => setState(() => _brycenReactionValue = val), isOptional: true),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: (_isLoading || !widget.guessingAllowed) ? null : _handleSaveGuess,
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(_existingGuess != null ? 'Update Guess' : 'Submit Guess'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 