import '../../domain/models.dart';

const List<StoryDef> deStories = [
  StoryDef(
    id: 'de_s1',
    title: 'At the café',
    emoji: '☕',
    lines: [
      StoryLine(
        'Lena',
        'Guten Morgen! Ich möchte einen Kaffee, bitte.',
        'Good morning! I would like a coffee, please.',
      ),
      StoryLine(
        'Lukas',
        'Guten Morgen! Einen Kaffee oder einen Cappuccino?',
        'Good morning! A coffee or a cappuccino?',
      ),
      StoryLine(
        'Lena',
        'Einen Cappuccino, danke. Wie viel kostet das?',
        'A cappuccino, thank you. How much does it cost?',
      ),
      StoryLine(
        'Lukas',
        'Das kostet zwei Euro fünfzig.',
        'It costs two euros and fifty cents.',
      ),
      StoryLine(
        'Lena',
        'Hier sind drei Euro. Danke!',
        'Here are three euros. Thank you!',
      ),
      StoryLine(
        'Lukas',
        'Hier ist das Wechselgeld, fünfzig Cent. Schönen Tag noch!',
        'Here is your change, fifty cents. Have a good day!',
      ),
      StoryLine(
        'Lena',
        'Danke, bis bald!',
        'Thanks, see you soon!',
      ),
    ],
    questions: [
      StoryQuestion(
        'What does Lena order?',
        ['A cappuccino', 'A cup of tea', 'A glass of water'],
        0,
      ),
      StoryQuestion(
        'How much does the cappuccino cost?',
        ['Three euros', 'Two euros fifty', 'Fifty cents'],
        1,
      ),
      StoryQuestion(
        'What does Lukas say at the end?',
        ['Good night', 'Happy birthday', 'Have a good day'],
        2,
      ),
    ],
  ),
  StoryDef(
    id: 'de_s2',
    title: 'Meeting a neighbour',
    emoji: '🏠',
    lines: [
      StoryLine(
        'Sara',
        'Hallo! Ich bin Sara. Ich wohne hier, in der Nummer fünf.',
        'Hi! I am Sara. I live here, at number five.',
      ),
      StoryLine(
        'Jonas',
        'Freut mich, Sara! Ich bin Jonas. Ich wohne in der Nummer sechs.',
        'Nice to meet you, Sara! I am Jonas. I live at number six.',
      ),
      StoryLine(
        'Sara',
        'Bist du Deutscher?',
        'Are you German?',
      ),
      StoryLine(
        'Jonas',
        'Nein, ich komme aus London. Ich spreche ein bisschen Deutsch.',
        'No, I am from London. I speak a little German.',
      ),
      StoryLine(
        'Sara',
        'Willkommen! Gefällt dir die Stadt?',
        'Welcome! Do you like the city?',
      ),
      StoryLine(
        'Jonas',
        'Ja, sie gefällt mir sehr! Meine Wohnung ist klein, aber schön.',
        'Yes, I like it a lot! My flat is small but nice.',
      ),
      StoryLine(
        'Sara',
        'Sehen wir uns morgen in der Bar?',
        'See you tomorrow at the bar?',
      ),
      StoryLine(
        'Jonas',
        'Natürlich! Bis morgen.',
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
        'Where is Jonas from?',
        ['Berlin', 'Munich', 'London'],
        2,
      ),
      StoryQuestion(
        'What does Jonas say about his flat?',
        ['It is big and old', 'It is small but nice', 'It is dark and cold'],
        1,
      ),
    ],
  ),
  StoryDef(
    id: 'de_s3',
    title: 'Asking for directions',
    emoji: '🧭',
    lines: [
      StoryLine(
        'Anna',
        'Entschuldigung, wo ist der Bahnhof?',
        'Excuse me, where is the station?',
      ),
      StoryLine(
        'Herr Becker',
        'Der Bahnhof ist in der Nähe. Gehen Sie geradeaus, dann biegen Sie rechts ab.',
        'The station is near. Go straight, then turn right.',
      ),
      StoryLine(
        'Anna',
        'Wie viele Minuten zu Fuß?',
        'How many minutes on foot?',
      ),
      StoryLine(
        'Herr Becker',
        'Fünf Minuten. Das ist einfach!',
        'Five minutes. It is easy!',
      ),
      StoryLine(
        'Anna',
        'Vielen Dank. Und das Museum? Wo ist es?',
        'Thank you very much. And the museum? Where is it?',
      ),
      StoryLine(
        'Herr Becker',
        'Das Museum ist weit weg. Nehmen Sie die Straßenbahn Nummer acht.',
        'The museum is far. Take tram number eight.',
      ),
      StoryLine(
        'Anna',
        'Perfekt! Danke, Herr Becker.',
        'Perfect! Thanks, Herr Becker.',
      ),
      StoryLine(
        'Herr Becker',
        'Gern geschehen! Gute Reise!',
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
        'Which tram does Herr Becker tell Anna to take?',
        ['Number five', 'Number six', 'Number eight'],
        2,
      ),
    ],
  ),
  StoryDef(
    id: 'de_s4',
    title: 'At the market',
    emoji: '🍎',
    lines: [
      StoryLine(
        'Anna',
        'Guten Morgen, Herr Vogel! Wie geht es Ihnen?',
        'Good morning, Mr Vogel! How are you?',
      ),
      StoryLine(
        'Herr Vogel',
        'Gut, danke! Was möchten Sie?',
        'Fine, thanks! What would you like?',
      ),
      StoryLine(
        'Anna',
        'Ich möchte ein Kilo Äpfel und zwei Orangen.',
        'I would like one kilo of apples and two oranges.',
      ),
      StoryLine(
        'Herr Vogel',
        'Hier sind die Äpfel. Sie sind sehr gut!',
        'Here are the apples. They are very good!',
      ),
      StoryLine(
        'Anna',
        'Was kosten die Orangen?',
        'How much do the oranges cost?',
      ),
      StoryLine(
        'Herr Vogel',
        'Sie kosten zwei Euro pro Kilo.',
        'They cost two euros a kilo.',
      ),
      StoryLine(
        'Anna',
        'Gut. Hier ist das Geld.',
        'Okay. Here is the money.',
      ),
      StoryLine(
        'Herr Vogel',
        'Danke, auf Wiedersehen!',
        'Thank you, goodbye!',
      ),
    ],
    questions: [
      StoryQuestion(
        'How many kilos of apples does Anna buy?',
        ['Half a kilo', 'Two kilos', 'One kilo'],
        2,
      ),
      StoryQuestion(
        'How much do the oranges cost?',
        ['One euro a kilo', 'Two euros a kilo', 'Five euros a kilo'],
        1,
      ),
      StoryQuestion(
        'What does Mr Vogel say about the apples?',
        ['They are very good', 'They are very small', 'They are very cold'],
        0,
      ),
    ],
  ),
  StoryDef(
    id: 'de_s5',
    title: 'A phone call',
    emoji: '📱',
    lines: [
      StoryLine(
        'Lena',
        'Hallo? Hallo, Davide!',
        'Hello? Hi, Davide!',
      ),
      StoryLine(
        'Lukas',
        'Hallo, Lena! Wie geht es dir?',
        'Hi, Lena! How are you?',
      ),
      StoryLine(
        'Lena',
        'Mir geht es gut, danke. Gehst du heute Abend ins Kino?',
        'I am fine, thanks. Are you going to the cinema tonight?',
      ),
      StoryLine(
        'Lukas',
        'Ja, ich gehe mit Jonas. Willst du mit uns kommen?',
        'Yes, I am going with Jonas. Do you want to come with us?',
      ),
      StoryLine(
        'Lena',
        'Gern! Um wie viel Uhr beginnt der Film?',
        'Gladly! What time does the film start?',
      ),
      StoryLine(
        'Lukas',
        'Um halb neun. Wir treffen uns um acht vor dem Kino.',
        'At half past eight. See you at eight in front of the cinema.',
      ),
      StoryLine(
        'Lena',
        'Perfekt. Bis später, tschüss!',
        'Perfect. See you later, bye!',
      ),
      StoryLine(
        'Lukas',
        'Bis später!',
        'See you later!',
      ),
    ],
    questions: [
      StoryQuestion(
        'Where are Lukas and Jonas going tonight?',
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
    id: 'de_s6',
    title: 'Ordering pizza',
    emoji: '🍕',
    lines: [
      StoryLine(
        'Lukas',
        'Guten Abend! Ein Tisch für zwei?',
        'Good evening! A table for two?',
      ),
      StoryLine(
        'Anna',
        'Ja, danke. Kann ich die Speisekarte sehen?',
        'Yes, thanks. Can I see the menu?',
      ),
      StoryLine(
        'Lukas',
        'Hier ist die Speisekarte. Heute ist die Pizza Margherita sehr gut.',
        'Here is the menu. Today the margherita pizza is very good.',
      ),
      StoryLine(
        'Anna',
        'Dann nehme ich eine Pizza Margherita, bitte. Und zu trinken?',
        'Then I will have a margherita pizza, please. And to drink?',
      ),
      StoryLine(
        'Lukas',
        'Stilles Wasser oder Sprudelwasser?',
        'Still or sparkling water?',
      ),
      StoryLine(
        'Anna',
        'Sprudelwasser, bitte.',
        'Sparkling water, please.',
      ),
      StoryLine(
        'Lukas',
        'Gut. Die Pizza kommt in zehn Minuten.',
        'Okay. The pizza arrives in ten minutes.',
      ),
      StoryLine(
        'Anna',
        'Vielen Dank!',
        'Thank you very much!',
      ),
    ],
    questions: [
      StoryQuestion(
        'Which pizza does Anna order?',
        ['Pepperoni', 'Margherita', 'Four cheese'],
        1,
      ),
      StoryQuestion(
        'What does Anna drink?',
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
