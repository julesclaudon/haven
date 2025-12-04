# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# ============================================
# Grief Stages (Kübler-Ross model) - Enriched descriptions
# ============================================
grief_stages_data = [
  {
    name: "Déni",
    description: "C'est le choc initial. Tu refuses d'accepter que c'est terminé. Tu te dis que c'est une simple dispute, qu'elle va revenir, que ce n'est qu'une pause. Tu vérifies ton téléphone constamment, tu analyses chaque message, chaque story. Cette phase est un mécanisme de protection naturel de ton cerveau face à une douleur trop intense. C'est normal, mais attention à ne pas t'y enfermer trop longtemps."
  },
  {
    name: "Colère",
    description: "La réalité commence à s'imposer et ça fait mal. Tu ressens de la rage - contre elle, contre toi, contre le monde entier. 'Comment a-t-elle pu me faire ça ?' 'Pourquoi moi ?' Tu peux avoir envie de lui envoyer des messages de reproche, de la confronter, de lui montrer ce qu'elle perd. Cette colère est saine si elle est canalisée - elle montre que tu reprends contact avec tes émotions. L'erreur serait de la retourner contre toi."
  },
  {
    name: "Marchandage",
    description: "C'est la phase des 'et si'. Et si j'avais été plus présent ? Et si je lui envoie un dernier message ? Et si je change, elle reviendra peut-être ? Tu négocies avec la réalité, tu imagines des scénarios où tu aurais pu faire différemment. Tu peux être tenté de la recontacter avec des promesses de changement. C'est ton cerveau qui essaie de reprendre le contrôle sur une situation qui t'échappe. Cette réflexion peut être utile pour apprendre, mais attention à ne pas tomber dans la culpabilité excessive."
  },
  {
    name: "Dépression",
    description: "La tristesse profonde s'installe. Tu réalises pleinement que c'est fini et cette prise de conscience est douloureuse. Tu peux avoir envie de rester au lit, de t'isoler, de ne plus rien faire. Les choses qui te faisaient plaisir avant ne t'intéressent plus. Tu repenses aux bons moments et ça te déchire. C'est la phase la plus difficile mais aussi la plus importante : tu fais enfin face à ta douleur au lieu de la fuir. C'est ici que la vraie guérison commence."
  },
  {
    name: "Acceptation",
    description: "Tu commences à entrevoir la lumière. Non, tu n'as pas 'oublié' et tu n'es pas 'guéri' - tu as simplement intégré cette expérience dans ton histoire. Tu peux penser à elle sans que ça te détruise. Tu recommences à faire des projets, à t'intéresser à de nouvelles choses, peut-être à de nouvelles personnes. Tu comprends que cette rupture t'a appris quelque chose sur toi. La douleur est toujours là parfois, mais elle ne dirige plus ta vie. Tu es prêt à avancer."
  }
]

grief_stages = grief_stages_data.map do |data|
  GriefStage.find_or_create_by!(name: data[:name]) do |stage|
    stage.description = data[:description]
  end
end

# Update existing records with new descriptions
grief_stages_data.each do |data|
  stage = GriefStage.find_by(name: data[:name])
  stage&.update!(description: data[:description])
end

puts "✓ #{GriefStage.count} grief stages created"

# ============================================
# Archetypes - 10 archetypes with descriptions
# ============================================
archetypes_data = [
  {
    archetype_name: "Le Chevalier",
    archetype_desc: "Tu te donnes corps et âme pour protéger et défendre celle que tu aimes. Tu places ses besoins avant les tiens, parfois jusqu'à t'oublier complètement. En relation, tu es loyal, dévoué, prêt à tout sacrifier. Le risque ? T'épuiser à force de donner sans recevoir, et attirer des partenaires qui profitent de ta générosité. Ta rupture t'apprend qu'une relation saine est un échange, pas un sacrifice."
  },
  {
    archetype_name: "Le Sauveur",
    archetype_desc: "Tu es attiré par les personnes en difficulté, celles qui ont besoin d'être 'réparées'. Tu ressens une mission : les aider, les soutenir, les transformer. Ta valeur personnelle est souvent liée à ce que tu apportes à l'autre. Le problème ? Tu peux confondre amour et sauvetage, et te retrouver avec des partenaires qui ne sont pas disponibles émotionnellement. Cette rupture t'invite à te demander : qui prend soin de toi ?"
  },
  {
    archetype_name: "L'Indépendant",
    archetype_desc: "Tu valorises par-dessus tout ta liberté et ton autonomie. Tu as du mal à te laisser aller à la vulnérabilité et à la dépendance émotionnelle. En relation, tu gardes toujours une distance de sécurité, une porte de sortie. Le défi ? Accepter qu'aimer c'est aussi accepter de dépendre un peu de l'autre. Cette rupture te pousse à explorer : est-ce que tu fuyais l'intimité par peur d'être blessé ?"
  },
  {
    archetype_name: "Le Romantique",
    archetype_desc: "Tu crois au grand amour, aux âmes sœurs, aux histoires qui durent toute une vie. Tu idéalises tes relations et as des attentes très élevées. Quand tu aimes, c'est avec passion et intensité. Le risque ? La déception quand la réalité ne correspond pas au rêve, et la difficulté à voir les red flags à travers les lunettes roses. Cette rupture t'apprend que l'amour réel est moins parfait mais plus profond que dans les films."
  },
  {
    archetype_name: "L'Anxieux",
    archetype_desc: "Tu as besoin de réassurance constante et tu crains l'abandon. L'incertitude dans la relation te génère beaucoup de stress. Tu peux devenir envahissant, demander des preuves d'amour, avoir peur du moindre silence. Cette anxiété trouve souvent ses racines dans ton enfance. Le travail ? Apprendre à te rassurer toi-même et à tolérer l'incertitude. Cette rupture, bien que douloureuse, est une opportunité de construire ta sécurité intérieure."
  },
  {
    archetype_name: "Le Caméléon",
    archetype_desc: "Tu t'adaptes à chaque partenaire, changeant de personnalité, de goûts, d'opinions pour lui plaire. Tu as peur que ton vrai toi ne soit pas assez bien, pas assez aimable. En relation, tu te perds en essayant de devenir ce que l'autre veut. Le danger ? Ne plus savoir qui tu es vraiment après la rupture. Cette séparation est l'occasion de te retrouver et de découvrir ce que TOI tu veux vraiment."
  },
  {
    archetype_name: "Le Perfectionniste",
    archetype_desc: "Tu as des standards très élevés - pour toi comme pour ta partenaire. Tu analyses, tu optimises, tu cherches toujours à améliorer la relation. Tu peux être critique, pointilleux, jamais vraiment satisfait. Le piège ? Aucune relation réelle ne sera jamais parfaite, et ta quête de perfection peut étouffer l'autre. Cette rupture t'invite à accepter l'imperfection - la tienne et celle des autres."
  },
  {
    archetype_name: "Le Fusionnel",
    archetype_desc: "Quand tu aimes, tu veux tout partager : chaque moment, chaque pensée, chaque activité. Tu as du mal avec les limites et tu peux ressentir la moindre distance comme un rejet. Ta relation devient le centre de ta vie, parfois au détriment de tes amis et passions. Le challenge ? Apprendre que l'amour sain inclut aussi des espaces séparés. Cette rupture est l'occasion de reconstruire ta propre identité."
  },
  {
    archetype_name: "Le Stratège",
    archetype_desc: "Tu abordes les relations avec ta tête plus qu'avec ton cœur. Tu calcules, tu planifies, tu essaies de garder le contrôle. Montrer ta vulnérabilité te semble dangereux, alors tu maintiens une façade. Le problème ? L'amour ne se contrôle pas, et ta partenaire peut se sentir tenue à distance. Cette rupture te confronte à des émotions que tu ne peux pas rationaliser - et c'est peut-être une bonne chose."
  },
  {
    archetype_name: "L'Intense",
    archetype_desc: "Tu vis tout à fond : les hauts sont très hauts, les bas sont très bas. Ta relation est un rollercoaster émotionnel fait de passions, de disputes, de réconciliations intenses. Tu as du mal avec la routine et le calme. Le risque ? Confondre intensité et amour, chaos et passion. Cette rupture t'apprend qu'une relation stable n'est pas forcément ennuyeuse, et que la paix peut être excitante aussi."
  }
]

archetypes = archetypes_data.map do |data|
  archetype = Archetype.find_or_initialize_by(archetype_name: data[:archetype_name])
  archetype.archetype_desc = data[:archetype_desc]
  archetype.save!
  archetype
end

puts "✓ #{Archetype.count} archetypes created"

# ============================================
# Test Users
# ============================================
users_data = [
  { email: "lucas@test.com", username: "Lucas", archetype_id: archetypes[0].id },  # Le Chevalier
  { email: "thomas@test.com", username: "Thomas", archetype_id: archetypes[4].id }, # L'Anxieux
  { email: "maxime@test.com", username: "Maxime", archetype_id: archetypes[3].id }  # Le Romantique
]

users = users_data.map do |data|
  User.find_or_create_by!(email: data[:email]) do |user|
    user.username = data[:username]
    user.password = "password123"
    user.archetype_id = data[:archetype_id]
  end
end

# Update archetype if user exists
users_data.each_with_index do |data, index|
  users[index].update!(archetype_id: data[:archetype_id])
end

puts "✓ #{User.count} users created"

# ============================================
# Initial Quizzes
# ============================================
initial_quizzes_data = [
  {
    user: users[0],
    age: 24,
    relation_end_date: 2.weeks.ago,
    relation_duration: 36,
    pain_level: 8,
    breakup_type: "soudaine",
    breakup_initiator: "elle",
    emotion_label: "confusion",
    main_sentiment: "Je ne comprends pas ce qui s'est passé. Tout allait bien entre nous, ou du moins c'est ce que je pensais.",
    ex_contact_frequency: "quotidien",
    considered_reunion: true,
    ruminating_frequency: "constamment",
    sleep_quality: "très mauvaise",
    habits_changed: "Je ne mange plus, je reste au lit, j'ai arrêté le sport",
    support_level: "quelques amis"
  },
  {
    user: users[1],
    age: 27,
    relation_end_date: 2.months.ago,
    relation_duration: 24,
    pain_level: 6,
    breakup_type: "progressive",
    breakup_initiator: "mutuel",
    emotion_label: "colère",
    main_sentiment: "Elle m'a trompé et je lui ai tout donné. Je me sens trahi et idiot d'avoir autant investi.",
    ex_contact_frequency: "hebdomadaire",
    considered_reunion: false,
    ruminating_frequency: "souvent",
    sleep_quality: "mauvaise",
    habits_changed: "Je bois plus qu'avant, je sors beaucoup pour oublier",
    support_level: "famille proche"
  },
  {
    user: users[2],
    age: 22,
    relation_end_date: 4.months.ago,
    relation_duration: 18,
    pain_level: 4,
    breakup_type: "progressive",
    breakup_initiator: "moi",
    emotion_label: "tristesse",
    main_sentiment: "C'était la bonne décision mais elle me manque quand même. Je me demande si j'aurais pu faire mieux.",
    ex_contact_frequency: "jamais",
    considered_reunion: false,
    ruminating_frequency: "parfois",
    sleep_quality: "correcte",
    habits_changed: "J'ai repris le sport, je vois plus mes amis",
    support_level: "très entouré"
  }
]

initial_quizzes = initial_quizzes_data.map do |data|
  InitialQuiz.find_or_create_by!(user: data[:user]) do |quiz|
    quiz.assign_attributes(data.except(:user))
  end
end

puts "✓ #{InitialQuiz.count} initial quizzes created"

# ============================================
# Emotion labels available: colère, tristesse, manque, espoir, confusion, culpabilité
# ============================================

# ============================================
# Multiple Chats, States and Analyses for Lucas (user[0])
# ============================================

# Clear existing states and chats for clean seed
State.where(user: users[0]).destroy_all
Chat.left_joins(:states).where(states: { id: nil }).destroy_all

lucas_journey = [
  # Chat 1 - Initial shock (2 weeks ago)
  {
    chat: { status: "completed" },
    state: {
      grief_stage: grief_stages[0], # Déni
      pain_level: 9,
      raw_input: "Elle m'a quitté hier soir. Je n'arrive pas à y croire. On devait partir en vacances le mois prochain. Elle a dit qu'elle ne m'aimait plus mais c'est impossible, on était si bien ensemble...",
      trigger_source: "message",
      time_of_day: "nuit",
      drugs: "alcool",
      emotion_label: "confusion",
      main_sentiment: "C'est impossible, elle va revenir",
      ex_contact_frequency: "quotidien",
      considered_reunion: true,
      ruminating_frequency: "constamment",
      sleep_quality: "très mauvaise",
      habits_changed: "Je n'ai pas dormi de la nuit",
      support_level: "isolé"
    },
    analysis: {
      score: 10,
      resume: "Lucas est en état de choc suite à une rupture très récente. Il présente tous les signes du déni : incapacité à accepter la réalité, recherche d'explications rationnelles, espoir de réconciliation. Son niveau de douleur est critique (9/10). Priorité immédiate : s'assurer qu'il n'est pas seul et qu'il prend soin de lui basiquement (manger, dormir)."
    },
    created_at: 14.days.ago
  },
  # Chat 2 - Still in denial (10 days ago)
  {
    chat: { status: "completed" },
    state: {
      grief_stage: grief_stages[0], # Déni
      pain_level: 8,
      raw_input: "J'ai vu qu'elle a liké une photo sur Instagram. C'est un signe non ? Si elle voulait vraiment me quitter, elle m'aurait bloqué. Je pense qu'elle teste juste ma réaction.",
      trigger_source: "instagram",
      time_of_day: "soir",
      drugs: "aucun",
      emotion_label: "espoir",
      main_sentiment: "Elle m'envoie des signes, j'en suis sûr",
      ex_contact_frequency: "quotidien",
      considered_reunion: true,
      ruminating_frequency: "constamment",
      sleep_quality: "mauvaise",
      habits_changed: "Je passe mon temps sur ses réseaux sociaux",
      support_level: "quelques amis"
    },
    analysis: {
      score: 15,
      resume: "Lucas reste dans le déni et interprète le moindre signal comme un espoir de réconciliation. Le stalking sur les réseaux sociaux est un comportement préoccupant qui entretient sa souffrance. Légère amélioration : il a parlé à quelques amis. Recommandation : l'encourager à limiter sa consultation des réseaux sociaux de son ex."
    },
    created_at: 10.days.ago
  },
  # Chat 3 - Transition to anger (7 days ago)
  {
    chat: { status: "completed" },
    state: {
      grief_stage: grief_stages[1], # Colère
      pain_level: 8,
      raw_input: "Je viens de voir qu'elle est sortie avec ses copines hier soir. Elle rigole sur les photos alors que moi je suis détruit. Comment elle peut faire ça ? Elle s'en fout complètement de moi en fait !",
      trigger_source: "instagram",
      time_of_day: "matin",
      drugs: "aucun",
      emotion_label: "colère",
      main_sentiment: "Elle n'en a rien à faire de moi",
      ex_contact_frequency: "hebdomadaire",
      considered_reunion: true,
      ruminating_frequency: "souvent",
      sleep_quality: "mauvaise",
      habits_changed: "J'ai commencé à aller courir pour évacuer",
      support_level: "quelques amis"
    },
    analysis: {
      score: 25,
      resume: "Lucas commence à sortir du déni et entre dans la phase de colère. C'est une progression naturelle et saine. Il ressent de l'injustice face à la situation. Point positif : il a repris une activité physique (course) et réduit le contact avec son ex. La colère est un moteur qui peut l'aider à avancer s'il la canalise bien."
    },
    created_at: 7.days.ago
  },
  # Chat 4 - Bargaining phase (4 days ago)
  {
    chat: { status: "completed" },
    state: {
      grief_stage: grief_stages[2], # Marchandage
      pain_level: 7,
      raw_input: "J'ai failli lui envoyer un message hier pour lui dire que j'avais compris mes erreurs. Je sais que j'ai pas toujours été présent avec mon travail. Si je lui promets de changer, peut-être que...",
      trigger_source: "mémoire",
      time_of_day: "après-midi",
      drugs: "aucun",
      emotion_label: "culpabilité",
      main_sentiment: "C'est peut-être de ma faute, je peux encore réparer",
      ex_contact_frequency: "jamais",
      considered_reunion: true,
      ruminating_frequency: "souvent",
      sleep_quality: "correcte",
      habits_changed: "Je cours tous les jours maintenant",
      support_level: "quelques amis"
    },
    analysis: {
      score: 35,
      resume: "Lucas entre dans la phase de marchandage. Il commence à prendre du recul et à réfléchir à sa part de responsabilité - ce qui est sain - mais risque de tomber dans la culpabilité excessive. Très positif : il n'a pas envoyé le message et a résisté à l'impulsion. Le sport quotidien est un excellent exutoire. Sommeil qui s'améliore."
    },
    created_at: 4.days.ago
  },
  # Chat 5 - Current state - mixed emotions (today)
  {
    chat: { status: "active" },
    state: {
      grief_stage: grief_stages[2], # Marchandage
      pain_level: 6,
      raw_input: "Ce matin j'allais bien et là j'ai entendu notre chanson dans un café. Ça m'a détruit. J'ai l'impression de faire un pas en avant et deux en arrière. Est-ce que ça va finir un jour ?",
      trigger_source: "chanson",
      time_of_day: "matin",
      drugs: "aucun",
      emotion_label: "manque",
      main_sentiment: "Elle me manque tellement",
      ex_contact_frequency: "jamais",
      considered_reunion: false,
      ruminating_frequency: "parfois",
      sleep_quality: "correcte",
      habits_changed: "Je maintiens le sport et j'ai revu mes amis ce weekend",
      support_level: "quelques amis"
    },
    analysis: {
      score: 42,
      resume: "Lucas montre une progression encourageante malgré les rechutes ponctuelles liées aux triggers. Il comprend que le processus n'est pas linéaire - c'est une prise de conscience importante. Points très positifs : il ne considère plus la réconciliation, maintient le sport, revoit ses amis. Le manque est normal et sain à ce stade. Recommandation : continuer sur cette lancée et être patient avec lui-même."
    },
    created_at: Time.current
  }
]

lucas_chats = []
lucas_states = []

lucas_journey.each do |data|
  chat = Chat.create!(data[:chat])
  lucas_chats << chat

  state = State.create!(
    data[:state].merge(
      user: users[0],
      chat: chat,
      created_at: data[:created_at],
      updated_at: data[:created_at]
    )
  )
  lucas_states << state

  Analysis.create!(
    data[:analysis].merge(
      state: state,
      created_at: data[:created_at],
      updated_at: data[:created_at]
    )
  )
end

puts "✓ #{lucas_chats.count} chats created for Lucas"

# ============================================
# Single chat for Thomas and Maxime
# ============================================

# Thomas
State.where(user: users[1]).destroy_all
thomas_chat = Chat.create!(status: "active")
thomas_state = State.create!(
  user: users[1],
  chat: thomas_chat,
  grief_stage: grief_stages[1], # Colère
  pain_level: 7,
  raw_input: "Comment elle a pu me faire ça ? Après tout ce que j'ai fait pour elle ! Je lui ai tout donné et voilà comment elle me remercie.",
  trigger_source: "mémoire",
  time_of_day: "soir",
  drugs: "aucun",
  emotion_label: "colère",
  main_sentiment: "Je suis en colère contre elle et contre moi-même",
  ex_contact_frequency: "hebdomadaire",
  considered_reunion: false,
  ruminating_frequency: "souvent",
  sleep_quality: "mauvaise",
  habits_changed: "Je fais du sport intensément pour évacuer",
  support_level: "quelques amis"
)

Analysis.create!(
  state: thomas_state,
  score: 35,
  resume: "Thomas traverse une phase de colère intense suite à une trahison. Il exprime beaucoup de ressentiment envers son ex-partenaire et une certaine culpabilité envers lui-même. Le sport lui sert d'exutoire ce qui est positif. Il a dépassé le déni mais doit travailler sur la gestion de sa colère pour éviter qu'elle ne devienne destructrice."
)

# Maxime
State.where(user: users[2]).destroy_all
maxime_chat = Chat.create!(status: "completed")
maxime_state = State.create!(
  user: users[2],
  chat: maxime_chat,
  grief_stage: grief_stages[4], # Acceptation
  pain_level: 3,
  raw_input: "Aujourd'hui j'ai croisé une fille qui lui ressemblait. Ça m'a fait un pincement mais j'ai continué ma journée normalement. Je crois que j'avance vraiment.",
  trigger_source: "lieu",
  time_of_day: "après-midi",
  drugs: "aucun",
  emotion_label: "espoir",
  main_sentiment: "J'avance, je suis sur la bonne voie",
  ex_contact_frequency: "jamais",
  considered_reunion: false,
  ruminating_frequency: "rarement",
  sleep_quality: "bonne",
  habits_changed: "J'ai repris mes passions et je me sens mieux",
  support_level: "très entouré"
)

Analysis.create!(
  state: maxime_state,
  score: 78,
  resume: "Maxime progresse très bien dans son processus de deuil. Il a atteint la phase d'acceptation et montre des signes encourageants : reprise des activités, bon réseau social, capacité à gérer les triggers sans être submergé. Il peut encore ressentir de la nostalgie occasionnelle mais elle ne l'empêche plus d'avancer."
)

puts "✓ #{Chat.count} total chats created"
puts "✓ #{State.count} total states created"
puts "✓ #{Analysis.count} total analyses created"

puts "\n🌱 Seeding completed!"
puts "   - #{User.count} users"
puts "   - #{GriefStage.count} grief stages"
puts "   - #{Archetype.count} archetypes"
puts "   - #{InitialQuiz.count} initial quizzes"
puts "   - #{Chat.count} chats"
puts "   - #{State.count} states"
puts "   - #{Analysis.count} analyses"
puts "\n📧 Test accounts:"
puts "   - lucas@test.com / password123 (5 chats, en progression)"
puts "   - thomas@test.com / password123 (1 chat, phase colère)"
puts "   - maxime@test.com / password123 (1 chat, phase acceptation)"
