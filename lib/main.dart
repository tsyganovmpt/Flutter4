import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B61F4)),
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

class Note {
  Note({
    required this.id,
    required this.text,
    this.isImportant = false,
  });

  final int id;
  String text;
  bool isImportant;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController controller = TextEditingController();
  final List<Note> notes = [];
  int nextNoteId = 0;

  void saveNote() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      notes.add(Note(id: nextNoteId++, text: text));
      controller.clear();
    });
  }

  void showNote(Note note) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Просмотр заметки')),
            if (note.isImportant)
              const Icon(Icons.star, color: Colors.amber),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(note.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void toggleImportant(Note note) {
    setState(() {
      note.isImportant = !note.isImportant;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            note.isImportant
                ? 'Заметка отмечена как важная'
                : 'Отметка важности снята',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> editNote(Note note) async {
    final editController = TextEditingController(text: note.text);

    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактирование заметки'),
        content: TextField(
          controller: editController,
          autofocus: true,
          minLines: 1,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Текст заметки',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, editController.text.trim());
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    editController.dispose();

    if (!mounted || updatedText == null || updatedText.isEmpty) return;

    setState(() {
      note.text = updatedText;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Изменения сохранены'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void deleteNote(Note note) {
    setState(() {
      notes.removeWhere((item) => item.id == note.id);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Заметка удалена'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  // Свайп вправо: вернуть важную заметку в обычный статус.
  Future<bool> handleSwipe(Note note, DismissDirection direction) async {
    if (direction == DismissDirection.endToStart) {
      deleteNote(note);
      return true;
    }

    if (direction == DismissDirection.startToEnd) {
      if (note.isImportant) {
        setState(() {
          note.isImportant = false;
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Обычный статус заметки восстановлен'),
              duration: Duration(seconds: 1),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Заметка уже имеет обычный статус'),
              duration: Duration(seconds: 1),
            ),
          );
      }
      return false;
    }

    return false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Введите заметку',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
              onSubmitted: (_) => saveNote(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveNote,
                icon: const Icon(Icons.add),
                label: const Text('Добавить заметку'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажатие — просмотр · Двойное — важная · '
              'Долгое — редактирование',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notes.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока нет заметок.\nДобавьте первую заметку!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];

                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) =>
                              handleSwipe(note, direction),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            child: const Row(
                              children: [
                                Icon(Icons.star_border, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Обычная',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Удалить',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.delete, color: Colors.white),
                              ],
                            ),
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => showNote(note),
                            onDoubleTap: () => toggleImportant(note),
                            onLongPress: () => editNote(note),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              color: note.isImportant
                                  ? Colors.amber.shade100
                                  : null,
                              child: ListTile(
                                leading: Icon(
                                  note.isImportant
                                      ? Icons.star
                                      : Icons.sticky_note_2_outlined,
                                  color: note.isImportant
                                      ? Colors.amber.shade800
                                      : null,
                                ),
                                title: Text(
                                  note.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  note.isImportant
                                      ? 'Важная заметка'
                                      : 'Обычная заметка',
                                ),
                                trailing: const Icon(
                                  Icons.touch_app_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 4),
            const Text(
              'дела у прокурора, а у нас делишки',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
