# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# ============================================
# Grief Stages (Kübler-Ross model)
# ============================================
grief_stages_data = [
  { name: "Déni", description: "Phase initiale où l'on refuse d'accepter la réalité de la rupture. On pense que c'est temporaire, qu'elle va revenir." },
  { name: "Colère", description: "Frustration et rage face à la situation. On cherche des coupables, on ressent de l'injustice." },
  { name: "Marchandage", description: "On tente de négocier, de trouver des solutions pour récupérer la relation. 'Et si j'avais fait différemment...'" },
  { name: "Dépression", description: "Tristesse profonde, perte de motivation. On réalise pleinement la perte et on la ressent intensément." },
  { name: "Acceptation", description: "On commence à accepter la fin de la relation et à envisager l'avenir. La douleur s'atténue progressivement." }
]

grief_stages = grief_stages_data.map do |data|
  GriefStage.find_or_create_by!(name: data[:name]) do |stage|
    stage.description = data[:description]
  end
end

puts "✓ #{GriefStage.count} grief stages created"

# ============================================
# Archetypes
# ============================================
archetypes_data = [
  { archetype_name: "Le Chevalier", archetype_desc: "Tu te donnes corps et âme pour protéger et sauver l'autre. Tu places souvent ses besoins avant les tiens, parfois au détriment de ton propre équilibre." },
  { archetype_name: "Le Sauveur", archetype_desc: "Tu es attiré par les personnes en difficulté et tu ressens le besoin de les aider, les réparer. Ta valeur est souvent liée à ce que tu apportes à l'autre." },
  { archetype_name: "L'Indépendant", archetype_desc: "Tu valorises ta liberté et ton autonomie. Tu peux avoir du mal à te laisser aller à la vulnérabilité et à la dépendance émotionnelle." },
  { archetype_name: "Le Romantique", archetype_desc: "Tu crois au grand amour et aux histoires passionnelles. Tu peux idéaliser tes relations et avoir des attentes très élevées." },
  { archetype_name: "L'Anxieux", archetype_desc: "Tu as besoin de réassurance constante et tu crains l'abandon. L'incertitude dans la relation te génère beaucoup de stress." }
]

archetypes = archetypes_data.map do |data|
  Archetype.find_or_create_by!(archetype_name: data[:archetype_name]) do |archetype|
    archetype.archetype_desc = data[:archetype_desc]
  end
end

puts "✓ #{Archetype.count} archetypes created"

# ============================================
# Test Users
# ============================================
users_data = [
  { email: "lucas@test.com", username: "Lucas", archetype_id: archetypes[0].id },
  { email: "thomas@test.com", username: "Thomas", archetype_id: archetypes[1].id },
  { email: "maxime@test.com", username: "Maxime", archetype_id: archetypes[3].id }
]

users = users_data.map do |data|
  User.find_or_create_by!(email: data[:email]) do |user|
    user.username = data[:username]
    user.password = "password123"
    user.archetype_id = data[:archetype_id]
  end
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
    emotion_label: "choc",
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
# Chats
# ============================================
chats = users.map do |user|
  Chat.find_or_create_by!(id: user.id) do |chat|
    chat.status = "active"
  end
end

puts "✓ #{Chat.count} chats created"

# ============================================
# States
# ============================================
states_data = [
  # Lucas - En phase de déni (score ~15)
  # trigger_source: instagram | facebook | linkedin | tiktok | snapchat | twitter | mémoire | message | chanson | lieu | photo | objet | rêve | autre
  {
    user: users[0],
    chat: chats[0],
    grief_stage: grief_stages[0], # Déni
    pain_level: 9,
    raw_input: "Je suis sûr qu'elle va revenir. On a juste besoin d'une pause. Elle m'a dit qu'elle m'aimait il y a 3 semaines...",
    trigger_source: "instagram",
    time_of_day: "nuit",
    drugs: "alcool",
    emotion_label: "confusion",
    main_sentiment: "Elle va revenir, j'en suis certain",
    ex_contact_frequency: "quotidien",
    considered_reunion: true,
    ruminating_frequency: "constamment",
    sleep_quality: "très mauvaise",
    habits_changed: "Je vérifie mon téléphone toutes les 5 minutes",
    support_level: "isolé"
  },
  # Thomas - En phase de colère (score ~35)
  {
    user: users[1],
    chat: chats[1],
    grief_stage: grief_stages[1], # Colère
    pain_level: 7,
    raw_input: "Comment elle a pu me faire ça ? Après tout ce que j'ai fait pour elle ! Je lui ai tout donné et voilà comment elle me remercie.",
    trigger_source: "mémoire",
    time_of_day: "soir",
    drugs: "aucun",
    emotion_label: "rage",
    main_sentiment: "Je suis en colère contre elle et contre moi-même",
    ex_contact_frequency: "hebdomadaire",
    considered_reunion: false,
    ruminating_frequency: "souvent",
    sleep_quality: "mauvaise",
    habits_changed: "Je fais du sport intensément pour évacuer",
    support_level: "quelques amis"
  },
  # Maxime - En phase d'acceptation (score ~75)
  {
    user: users[2],
    chat: chats[2],
    grief_stage: grief_stages[4], # Acceptation
    pain_level: 3,
    raw_input: "Aujourd'hui j'ai croisé une fille qui lui ressemblait. Ça m'a fait un pincement mais j'ai continué ma journée normalement.",
    trigger_source: "lieu",
    time_of_day: "après-midi",
    drugs: "aucun",
    emotion_label: "sérénité",
    main_sentiment: "J'avance, je suis sur la bonne voie",
    ex_contact_frequency: "jamais",
    considered_reunion: false,
    ruminating_frequency: "rarement",
    sleep_quality: "bonne",
    habits_changed: "J'ai repris mes passions et je me sens mieux",
    support_level: "très entouré"
  }
]

states = states_data.map do |data|
  State.create!(data)
end

puts "✓ #{State.count} states created"

# ============================================
# Analyses
# ============================================
analyses_data = [
  {
    state: states[0],
    score: 15,
    resume: "Lucas est actuellement en phase de déni. Il refuse d'accepter la fin de sa relation et maintient l'espoir d'une réconciliation malgré les signaux contraires. Son niveau de douleur est très élevé (9/10) et il présente des signes d'isolement social et de troubles du sommeil. Priorité : l'aider à prendre conscience de la réalité tout en validant ses émotions."
  },
  {
    state: states[1],
    score: 35,
    resume: "Thomas traverse une phase de colère intense suite à une trahison. Il exprime beaucoup de ressentiment envers son ex-partenaire et une certaine culpabilité envers lui-même. Le sport lui sert d'exutoire ce qui est positif. Il a dépassé le déni mais doit travailler sur la gestion de sa colère pour éviter qu'elle ne devienne destructrice."
  },
  {
    state: states[2],
    score: 75,
    resume: "Maxime progresse très bien dans son processus de deuil. Il a atteint la phase d'acceptation et montre des signes encourageants : reprise des activités, bon réseau social, capacité à gérer les triggers sans être submergé. Il peut encore ressentir de la nostalgie occasionnelle mais elle ne l'empêche plus d'avancer."
  }
]

analyses_data.each do |data|
  Analysis.find_or_create_by!(state: data[:state]) do |analysis|
    analysis.score = data[:score]
    analysis.resume = data[:resume]
  end
end

puts "✓ #{Analysis.count} analyses created"

puts "\n🌱 Seeding completed!"
puts "   - #{User.count} users"
puts "   - #{GriefStage.count} grief stages"
puts "   - #{Archetype.count} archetypes"
puts "   - #{InitialQuiz.count} initial quizzes"
puts "   - #{Chat.count} chats"
puts "   - #{State.count} states"
puts "   - #{Analysis.count} analyses"
