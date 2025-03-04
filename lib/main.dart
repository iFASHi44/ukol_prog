import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

TimeOfDay selectedTime = TimeOfDay.now();

class Data {
  static int idCounter = 0;

  final int id = idCounter++;
  final DateTime dateTime;
  final int fuelAmount;
  final double tachometerStart;
  final double tachometerEnd;
  final int pricePerLitre;
  final String notes;

  Data({required this.dateTime, required this.fuelAmount, required this.tachometerStart,
    required this.tachometerEnd, required this.pricePerLitre, required this.notes});
}

class DataStorage {
  static List<Data> dataList = [];

  static void add(Data data) {
    dataList.add(data);
  }

  static List<Data> getAll() {
    return dataList;
  }

  static Data? findByID(int id) {
    return dataList.firstWhere(
          (data) => data.id == id,
      orElse: () => Data(dateTime: DateTime.now(), fuelAmount: 0, pricePerLitre: 0, tachometerStart: 0.0, tachometerEnd: 0.0, notes: ""),
    );
  }

  static void removeById(int id) {
    dataList.removeWhere((data) => data.id == id);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController tachometerStart = TextEditingController();
  final TextEditingController tachometerEnd = TextEditingController();
  final TextEditingController fuelAmount = TextEditingController();
  final TextEditingController pricePerLitre = TextEditingController();
  final TextEditingController notes = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void submitForm() {
    if (formKey.currentState?.validate() ?? false) {

      DataStorage.add(Data(dateTime: _DatePickerState.selectedDate ?? DateTime.now(),
          fuelAmount: int.tryParse(fuelAmount.text) ?? 0,
          tachometerStart: double.tryParse(tachometerStart.text) ?? 0.0,
          tachometerEnd: double.tryParse(tachometerEnd.text) ?? 0.0,
          pricePerLitre: int.tryParse(pricePerLitre.text) ?? 0,
          notes: notes.text));

      // Clear the input fields
      tachometerStart.clear();
      tachometerEnd.clear();
      fuelAmount.clear();
      pricePerLitre.clear();
      notes.clear();

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text('Výpočet spotřeby paliva', style: TextStyle(color: Color(0xFF000000))),
        centerTitle: true,
        backgroundColor: Color(0xFFDCDCDC),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MyForm(
              formKey: formKey,
              vehicleTachometerStart: tachometerStart,
              vehicleTachometerEnd: tachometerEnd,
              fuelAmount: fuelAmount,
              pricePerLitre: pricePerLitre,
              notes: notes,
              submitForm: submitForm,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: DataStorage.getAll().length,
              itemBuilder: (context, index) {
                final data = DataStorage.getAll()[index];
                final notes = data.notes;
                final consumption = calculateFuelConsumption(data);
                return ListTile(
                  title: Text(DateFormat('yyyy-MM-dd').format(data.dateTime)),
                  subtitle: Text('Spotřeba: $consumption litrů/100km\n$notes'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Remove the data from the list
                      DataStorage.removeById(data.id);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String calculateFuelConsumption(Data data) {
    double distance = data.tachometerEnd - data.tachometerStart;

    if (distance <= 0) {
      return "0.0";
    }

    return format((data.fuelAmount / distance) * 100);
  }

  String format(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
  }
}

class MyForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController vehicleTachometerStart;
  final TextEditingController vehicleTachometerEnd;
  final TextEditingController fuelAmount;
  final TextEditingController pricePerLitre;
  final TextEditingController notes;
  final VoidCallback submitForm;

  const MyForm({
    super.key,
    required this.formKey,
    required this.vehicleTachometerStart,
    required this.vehicleTachometerEnd,
    required this.fuelAmount,
    required this.pricePerLitre,
    required this.notes,
    required this.submitForm,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: vehicleTachometerStart,
            decoration: InputDecoration(labelText: 'Počáteční stav tachometru'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d+)?$')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Prosím zadejte číslo';
              }
              return null;
            },
          ),
          TextFormField(
            controller: vehicleTachometerEnd,
            decoration: InputDecoration(labelText: 'Koncový stav tachometru'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d+)?$')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Prosím zadejte číslo';
              }
              return null;
            },
          ),
          TextFormField(
            controller: fuelAmount,
            decoration: InputDecoration(labelText: 'Množství paliva (v litrech)'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Prosím zadejte číslo';
              }
              return null;
            },
          ),
          TextFormField(
            controller: pricePerLitre,
            decoration: InputDecoration(labelText: 'Cena za litr'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Prosím zadejte číslo';
              }
              return null;
            },
          ),
          TextFormField(
            controller: notes,
            decoration: InputDecoration(labelText: 'Poznámky'),
            keyboardType: TextInputType.text,
          ),

          Padding(padding: EdgeInsets.symmetric(vertical: 25.0)),
          const DatePicker(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: submitForm,
              child: Text('Přidat nový záznam'),
            ),
          ),
        ],
      ),
    );
  }
}

class DatePicker extends StatefulWidget {
  const DatePicker({super.key});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  static DateTime? selectedDate;

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2021, 7, 25),
      firstDate: DateTime(2021),
      lastDate: DateTime(2022),
    );

    setState(() {
      selectedDate = pickedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Aligns to the left
      children: <Widget>[
        Center(child: Text("Datum tankování:", style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(height: 20), // Adds spacing between the text and button
        Center(child:
        ElevatedButton(
            onPressed: _selectDate,
            child: Text(selectedDate != null
                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                : 'Vyberte datum')
        )),
      ],
    );
  }
}
