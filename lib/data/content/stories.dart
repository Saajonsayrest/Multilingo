import '../../domain/models.dart';

const List<StoryDef> stories = [
  StoryDef(
    id: 's1',
    title: 'At the café',
    emoji: '☕',
    lines: [
      StoryLine(
        'Giulia',
        'Buongiorno! Vorrei un caffè, per favore.',
        'Good morning! I would like a coffee, please.',
      ),
      StoryLine(
        'Luca',
        'Buongiorno! Un caffè o un cappuccino?',
        'Good morning! A coffee or a cappuccino?',
      ),
      StoryLine(
        'Giulia',
        'Un cappuccino, grazie. Quanto costa?',
        'A cappuccino, thank you. How much does it cost?',
      ),
      StoryLine(
        'Luca',
        'Costa due euro e cinquanta.',
        'It costs two euros and fifty cents.',
      ),
      StoryLine(
        'Giulia',
        'Ecco tre euro. Grazie!',
        'Here are three euros. Thank you!',
      ),
      StoryLine(
        'Luca',
        'Ecco il resto, cinquanta centesimi. Buona giornata!',
        'Here is your change, fifty cents. Have a good day!',
      ),
      StoryLine(
        'Giulia',
        'Grazie, a presto!',
        'Thanks, see you soon!',
      ),
    ],
    questions: [
      StoryQuestion(
        'What does Giulia order?',
        ['A cappuccino', 'A cup of tea', 'A glass of water'],
        0,
      ),
      StoryQuestion(
        'How much does the cappuccino cost?',
        ['Three euros', 'Two euros fifty', 'Fifty cents'],
        1,
      ),
      StoryQuestion(
        'What does Luca say at the end?',
        ['Good night', 'Happy birthday', 'Have a good day'],
        2,
      ),
    ],
  ),
  StoryDef(
    id: 's2',
    title: 'Meeting a neighbour',
    emoji: '🏠',
    lines: [
      StoryLine(
        'Sara',
        'Ciao! Io sono Sara. Abito qui, al numero cinque.',
        "Hi! I am Sara. I live here, at number five.",
      ),
      StoryLine(
        'Marco',
        'Piacere, Sara! Io sono Marco. Abito al numero sei.',
        'Nice to meet you, Sara! I am Marco. I live at number six.',
      ),
      StoryLine(
        'Sara',
        'Sei italiano?',
        'Are you Italian?',
      ),
      StoryLine(
        'Marco',
        "No, sono di Londra. Parlo un po' di italiano.",
        'No, I am from London. I speak a little Italian.',
      ),
      StoryLine(
        'Sara',
        'Benvenuto! Ti piace la città?',
        'Welcome! Do you like the city?',
      ),
      StoryLine(
        'Marco',
        'Sì, mi piace molto! Il mio appartamento è piccolo ma bello.',
        'Yes, I like it a lot! My flat is small but nice.',
      ),
      StoryLine(
        'Sara',
        'Ci vediamo domani al bar?',
        'See you tomorrow at the bar?',
      ),
      StoryLine(
        'Marco',
        'Certo! A domani.',
        'Of course! See you tomorrow.',
      ),
    ],
    questions: [
      StoryQuestion(
        'Where does Sara live?',
        ['At number six', 'At number five', 'In London'],
        1,
      ),
      StoryQuestion(
        'Where is Marco from?',
        ['Milan', 'Rome', 'London'],
        2,
      ),
      StoryQuestion(
        'What does Marco say about his flat?',
        ['It is big and old', 'It is small but nice', 'It is dark and cold'],
        1,
      ),
    ],
  ),
  StoryDef(
    id: 's3',
    title: 'Asking for directions',
    emoji: '🧭',
    lines: [
      StoryLine(
        'Anna',
        "Scusi, dov'è la stazione?",
        'Excuse me, where is the station?',
      ),
      StoryLine(
        'Pietro',
        'La stazione è vicino. Va dritto, poi gira a destra.',
        'The station is near. Go straight, then turn right.',
      ),
      StoryLine(
        'Anna',
        'Quanti minuti a piedi?',
        'How many minutes on foot?',
      ),
      StoryLine(
        'Pietro',
        'Cinque minuti. È facile!',
        'Five minutes. It is easy!',
      ),
      StoryLine(
        'Anna',
        'Grazie mille. E il museo? Dov\'è?',
        'Thank you very much. And the museum? Where is it?',
      ),
      StoryLine(
        'Pietro',
        'Il museo è lontano. Prendi il tram numero otto.',
        'The museum is far. Take tram number eight.',
      ),
      StoryLine(
        'Anna',
        'Perfetto! Grazie, Pietro.',
        'Perfect! Thanks, Pietro.',
      ),
      StoryLine(
        'Pietro',
        'Prego! Buon viaggio!',
        'You are welcome! Have a good trip!',
      ),
    ],
    questions: [
      StoryQuestion(
        'What is Anna looking for first?',
        ['The station', 'The museum', 'The bank'],
        0,
      ),
      StoryQuestion(
        'How many minutes is the walk to the station?',
        ['Ten minutes', 'Five minutes', 'Eight minutes'],
        1,
      ),
      StoryQuestion(
        'Which tram does Pietro tell Anna to take?',
        ['Number five', 'Number six', 'Number eight'],
        2,
      ),
    ],
  ),
  StoryDef(
    id: 's4',
    title: 'At the market',
    emoji: '🍎',
    lines: [
      StoryLine(
        'Chiara',
        'Buongiorno, signor Franco! Come sta?',
        'Good morning, Mr Franco! How are you?',
      ),
      StoryLine(
        'Franco',
        'Bene, grazie! Che cosa desidera?',
        'Fine, thanks! What would you like?',
      ),
      StoryLine(
        'Chiara',
        'Vorrei un chilo di mele e due arance.',
        'I would like one kilo of apples and two oranges.',
      ),
      StoryLine(
        'Franco',
        'Ecco le mele. Sono molto buone!',
        'Here are the apples. They are very good!',
      ),
      StoryLine(
        'Chiara',
        'Quanto costano le arance?',
        'How much do the oranges cost?',
      ),
      StoryLine(
        'Franco',
        'Costano due euro al chilo.',
        'They cost two euros a kilo.',
      ),
      StoryLine(
        'Chiara',
        'Va bene. Ecco i soldi.',
        'Okay. Here is the money.',
      ),
      StoryLine(
        'Franco',
        'Grazie, arrivederci!',
        'Thank you, goodbye!',
      ),
    ],
    questions: [
      StoryQuestion(
        'How many kilos of apples does Chiara buy?',
        ['Half a kilo', 'Two kilos', 'One kilo'],
        2,
      ),
      StoryQuestion(
        'How much do the oranges cost?',
        ['One euro a kilo', 'Two euros a kilo', 'Five euros a kilo'],
        1,
      ),
      StoryQuestion(
        'What does Franco say about the apples?',
        ['They are very good', 'They are very small', 'They are very cold'],
        0,
      ),
    ],
  ),
  StoryDef(
    id: 's5',
    title: 'A phone call',
    emoji: '📱',
    lines: [
      StoryLine(
        'Elena',
        'Pronto? Ciao, Davide!',
        'Hello? Hi, Davide!',
      ),
      StoryLine(
        'Davide',
        'Ciao, Elena! Come stai?',
        'Hi, Elena! How are you?',
      ),
      StoryLine(
        'Elena',
        'Sto bene, grazie. Stasera vai al cinema?',
        'I am fine, thanks. Are you going to the cinema tonight?',
      ),
      StoryLine(
        'Davide',
        'Sì, vado con Marco. Vuoi venire con noi?',
        'Yes, I am going with Marco. Do you want to come with us?',
      ),
      StoryLine(
        'Elena',
        'Volentieri! A che ora inizia il film?',
        'Gladly! What time does the film start?',
      ),
      StoryLine(
        'Davide',
        'Alle otto e mezza. Ci vediamo alle otto davanti al cinema.',
        'At half past eight. See you at eight in front of the cinema.',
      ),
      StoryLine(
        'Elena',
        'Perfetto. A dopo, ciao!',
        'Perfect. See you later, bye!',
      ),
      StoryLine(
        'Davide',
        'A dopo!',
        'See you later!',
      ),
    ],
    questions: [
      StoryQuestion(
        'Where are Davide and Marco going tonight?',
        ['To the cinema', 'To the market', 'To the station'],
        0,
      ),
      StoryQuestion(
        'What time does the film start?',
        ["Eight o'clock", 'Half past eight', 'Nine o\'clock'],
        1,
      ),
      StoryQuestion(
        'Where do they meet?',
        ['At the café', 'At home', 'In front of the cinema'],
        2,
      ),
    ],
  ),
  StoryDef(
    id: 's6',
    title: 'Ordering pizza',
    emoji: '🍕',
    lines: [
      StoryLine(
        'Luca',
        'Buonasera! Un tavolo per due?',
        'Good evening! A table for two?',
      ),
      StoryLine(
        'Giulia',
        'Sì, grazie. Posso vedere il menu?',
        'Yes, thanks. Can I see the menu?',
      ),
      StoryLine(
        'Luca',
        'Ecco il menu. Oggi la pizza margherita è molto buona.',
        'Here is the menu. Today the margherita pizza is very good.',
      ),
      StoryLine(
        'Giulia',
        'Allora prendo una pizza margherita, per favore. E da bere?',
        'Then I will have a margherita pizza, please. And to drink?',
      ),
      StoryLine(
        'Luca',
        'Acqua naturale o frizzante?',
        'Still or sparkling water?',
      ),
      StoryLine(
        'Giulia',
        'Acqua frizzante, per favore.',
        'Sparkling water, please.',
      ),
      StoryLine(
        'Luca',
        'Va bene. La pizza arriva tra dieci minuti.',
        'Okay. The pizza arrives in ten minutes.',
      ),
      StoryLine(
        'Giulia',
        'Grazie mille!',
        'Thank you very much!',
      ),
    ],
    questions: [
      StoryQuestion(
        'Which pizza does Giulia order?',
        ['Pepperoni', 'Margherita', 'Four cheese'],
        1,
      ),
      StoryQuestion(
        'What does Giulia drink?',
        ['Sparkling water', 'Still water', 'Red wine'],
        0,
      ),
      StoryQuestion(
        'How long will the pizza take?',
        ['Five minutes', 'Twenty minutes', 'Ten minutes'],
        2,
      ),
    ],
  ),
];
