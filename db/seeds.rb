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
# Test User
# ============================================
user = User.find_or_create_by!(email: "test@haven.com") do |u|
  u.username = "TestUser"
  u.password = "password123"
  u.archetype_id = archetypes[3].id # Le Romantique
end

puts "✓ 1 user created"

# ============================================
# Initial Quiz
# ============================================
initial_quiz = InitialQuiz.find_or_create_by!(user: user) do |quiz|
  quiz.age = 25
  quiz.relation_end_date = 3.months.ago
  quiz.relation_duration = 24
  quiz.pain_level = 7
  quiz.breakup_type = "progressive"
  quiz.breakup_initiator = "elle"
  quiz.emotion_label = "tristesse"
  quiz.main_sentiment = "Je pensais qu'on allait construire quelque chose ensemble. Je ne m'attendais pas à ce qu'elle parte."
  quiz.ex_contact_frequency = "hebdomadaire"
  quiz.considered_reunion = true
  quiz.ruminating_frequency = "souvent"
  quiz.sleep_quality = "mauvaise"
  quiz.habits_changed = "J'ai du mal à me concentrer au travail, je sors moins"
  quiz.support_level = "quelques amis"
end

puts "✓ 1 initial quiz created"

# ============================================
# Chats, States et Analyses - 5 sessions historiques
# 1 chat = 1 state = 1 analyse
# trigger_source: instagram | facebook | linkedin | tiktok | snapchat | twitter | mémoire | message | chanson | lieu | photo | objet | rêve | autre
# ============================================
sessions_data = [
  # Session 1 - Il y a 3 mois - Phase de Déni (score ~10)
  {
    created_at: 3.months.ago,
    state: {
      grief_stage: grief_stages[0], # Déni
      pain_level: 9,
      raw_input: "C'est juste une pause, elle a besoin de temps. On va se retrouver, j'en suis sûr. Elle m'a dit qu'elle m'aimait encore la semaine dernière.",
      trigger_source: "message",
      time_of_day: "nuit",
      drugs: "alcool",
      emotion_label: "confusion",
      main_sentiment: "Elle va revenir, c'est évident",
      ex_contact_frequency: "quotidien",
      considered_reunion: true,
      ruminating_frequency: "constamment",
      sleep_quality: "très mauvaise",
      habits_changed: "Je relis nos conversations en boucle",
      support_level: "isolé"
    },
    analysis: {
      score: 10,
      resume: "L'utilisateur est en pleine phase de déni. Il refuse d'accepter la rupture et maintient l'espoir d'une réconciliation. Niveau de douleur très élevé (9/10), isolement social, troubles du sommeil. Il relit obsessionnellement les anciennes conversations. Priorité : l'aider à prendre conscience de la réalité progressivement."
    }
  },
  # Session 2 - Il y a 2 mois - Phase de Colère (score ~25)
  {
    created_at: 2.months.ago,
    state: {
      grief_stage: grief_stages[1], # Colère
      pain_level: 8,
      raw_input: "Je lui ai tout donné et elle m'a jeté comme une merde. 2 ans de ma vie pour ça. Je la déteste.",
      trigger_source: "instagram",
      time_of_day: "soir",
      drugs: "aucun",
      emotion_label: "rage",
      main_sentiment: "Elle m'a trahi, je ne lui pardonnerai jamais",
      ex_contact_frequency: "hebdomadaire",
      considered_reunion: false,
      ruminating_frequency: "souvent",
      sleep_quality: "mauvaise",
      habits_changed: "Je fais du sport pour évacuer la colère",
      support_level: "quelques amis"
    },
    analysis: {
      score: 25,
      resume: "L'utilisateur est entré dans une phase de colère intense. Il exprime du ressentiment envers son ex et un sentiment de trahison. Le sport comme exutoire est positif. La douleur reste élevée (8/10) mais il commence à s'entourer. Il doit apprendre à canaliser sa colère de manière constructive."
    }
  },
  # Session 3 - Il y a 1 mois - Phase de Marchandage (score ~45)
  {
    created_at: 1.month.ago,
    state: {
      grief_stage: grief_stages[2], # Marchandage
      pain_level: 6,
      raw_input: "Et si j'avais été plus présent ? Si j'avais fait plus attention à elle ? Peut-être que si je change, on pourrait réessayer...",
      trigger_source: "photo",
      time_of_day: "après-midi",
      drugs: "aucun",
      emotion_label: "regret",
      main_sentiment: "J'aurais pu faire mieux, c'est peut-être ma faute",
      ex_contact_frequency: "mensuel",
      considered_reunion: true,
      ruminating_frequency: "souvent",
      sleep_quality: "correcte",
      habits_changed: "Je réfléchis beaucoup à ce que j'aurais pu changer",
      support_level: "quelques amis"
    },
    analysis: {
      score: 45,
      resume: "L'utilisateur traverse la phase de marchandage. Il se remet en question et cherche ce qu'il aurait pu faire différemment. C'est une étape nécessaire mais il ne doit pas s'enliser dans la culpabilité. La douleur diminue (6/10), le sommeil s'améliore. Il progresse."
    }
  },
  # Session 4 - Il y a 2 semaines - Phase de Dépression (score ~55)
  {
    created_at: 2.weeks.ago,
    state: {
      grief_stage: grief_stages[3], # Dépression
      pain_level: 7,
      raw_input: "Je me sens vide. Rien ne me fait plaisir. Je ne sais pas si je vais m'en remettre un jour.",
      trigger_source: "chanson",
      time_of_day: "nuit",
      drugs: "aucun",
      emotion_label: "tristesse profonde",
      main_sentiment: "Je suis perdu, tout me semble fade",
      ex_contact_frequency: "jamais",
      considered_reunion: false,
      ruminating_frequency: "souvent",
      sleep_quality: "mauvaise",
      habits_changed: "Je reste beaucoup chez moi, j'ai moins d'énergie",
      support_level: "famille proche"
    },
    analysis: {
      score: 55,
      resume: "L'utilisateur est dans une phase dépressive. Il ressent un vide et une perte de sens. C'est la phase la plus difficile mais aussi un signe qu'il accepte progressivement la réalité. Il s'appuie sur sa famille, ce qui est positif. Surveiller son moral et l'encourager à maintenir des activités."
    }
  },
  # Session 5 - Aujourd'hui - Début d'Acceptation (score ~65)
  {
    created_at: Time.current,
    state: {
      grief_stage: grief_stages[4], # Acceptation
      pain_level: 4,
      raw_input: "J'ai passé un bon moment avec mes potes hier. J'ai pensé à elle mais ça m'a pas gâché la soirée. Je commence à me dire que je vais m'en sortir.",
      trigger_source: "lieu",
      time_of_day: "après-midi",
      drugs: "aucun",
      emotion_label: "espoir",
      main_sentiment: "Je vais m'en sortir, je le sens",
      ex_contact_frequency: "jamais",
      considered_reunion: false,
      ruminating_frequency: "parfois",
      sleep_quality: "correcte",
      habits_changed: "Je ressors, je reprends mes activités",
      support_level: "très entouré"
    },
    analysis: {
      score: 65,
      resume: "L'utilisateur montre des signes encourageants d'acceptation. Il arrive à profiter de moments avec ses amis sans être submergé par la tristesse. La douleur a significativement diminué (4/10). Il reprend ses activités et son réseau social est solide. Il est sur la bonne voie vers la guérison."
    }
  }
]

sessions_data.each do |session|
  # Créer le chat
  chat = Chat.create!(status: "completed")
  chat.update_columns(created_at: session[:created_at], updated_at: session[:created_at])

  # Créer le state
  state = State.create!(
    user: user,
    chat: chat,
    **session[:state]
  )
  state.update_columns(created_at: session[:created_at], updated_at: session[:created_at])

  # Créer l'analyse
  analysis = Analysis.create!(
    state: state,
    **session[:analysis]
  )
  analysis.update_columns(created_at: session[:created_at], updated_at: session[:created_at])
end

puts "✓ #{Chat.count} chats created"
puts "✓ #{State.count} states created"
puts "✓ #{Analysis.count} analyses created"

puts "\n🌱 Seeding completed!"
puts "   - #{User.count} user (test@haven.com / password123)"
puts "   - #{GriefStage.count} grief stages"
puts "   - #{Archetype.count} archetypes"
puts "   - #{InitialQuiz.count} initial quiz"
puts "   - #{Chat.count} chats (1 par session)"
puts "   - #{State.count} states (1 par chat)"
puts "   - #{Analysis.count} analyses (1 par state)"
