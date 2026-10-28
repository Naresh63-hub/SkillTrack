import 'database_helper.dart';

class SampleData {
  /// Loads comprehensive demonstration data for college presentation & portfolio showcase.
  /// Never loaded automatically; only when the user explicitly triggers "Load Demo Data".
  static Future<void> loadDemoData() async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Clear existing to avoid duplicate conflicts
      await txn.delete('achievements');
      await txn.delete('education');
      await txn.delete('job_applications');
      await txn.delete('interview_questions');
      await txn.delete('placement_topics');
      await txn.delete('learning_goals');
      await txn.delete('tasks');
      await txn.delete('projects');
      await txn.delete('certificates');
      await txn.delete('skills');
      await txn.delete('student_profile');

      final now = DateTime.now();

      // 1. Student Profile (Matching design mockup Screen 4 & 14)
      await txn.insert('student_profile', {
        'name': 'Priya Sharma',
        'email': 'priya.sharma@college.edu',
        'phone': '+91 98765 43210',
        'city': 'Bengaluru, India',
        'college': 'B.Tech - Tech Institute',
        'degree': 'Bachelor of Technology (B.Tech)',
        'branch': 'Computer Science',
        'current_semester': '6th Semester',
        'graduation_year': '2026',
        'target_job_role': 'Software Developer',
        'github_url': 'https://github.com/priya',
        'linkedin_url': 'https://linkedin.com/in/priya',
        'portfolio_url': 'https://priyasharma.dev',
        'bio':
            'Dedicated 6th Semester B.Tech Computer Science student preparing for software engineering and full-stack development placements.',
        'updated_at': now.toIso8601String(),
      });

      // 2. Technical Skills (Matching design mockup Screen 5)
      final skillsData = [
        {
          'name': 'Python',
          'category': 'Programming Languages',
          'proficiency_level': 'Intermediate',
          'progress_percentage': 65.0,
          'date_started':
              now.subtract(const Duration(days: 180)).toIso8601String(),
          'target_completion_date':
              now.add(const Duration(days: 30)).toIso8601String(),
          'learning_resource_url': 'https://docs.python.org',
          'notes':
              'Data structures, OOP, file handling, and algorithms.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'Flutter',
          'category': 'Mobile Development',
          'proficiency_level': 'Advanced',
          'progress_percentage': 80.0,
          'date_started':
              now.subtract(const Duration(days: 240)).toIso8601String(),
          'target_completion_date':
              now.add(const Duration(days: 45)).toIso8601String(),
          'learning_resource_url': 'https://flutter.dev',
          'notes':
              'Cross-platform UI, state management, SQLite integration, and animations.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'Java',
          'category': 'Programming Languages',
          'proficiency_level': 'Intermediate',
          'progress_percentage': 60.0,
          'date_started':
              now.subtract(const Duration(days: 150)).toIso8601String(),
          'target_completion_date':
              now.add(const Duration(days: 60)).toIso8601String(),
          'learning_resource_url': 'https://dev.java',
          'notes':
              'Core Java, Collections Framework, Multi-threading, and Streams.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'Dart',
          'category': 'Programming Languages',
          'proficiency_level': 'Beginner',
          'progress_percentage': 40.0,
          'date_started':
              now.subtract(const Duration(days: 90)).toIso8601String(),
          'target_completion_date':
              now.add(const Duration(days: 30)).toIso8601String(),
          'learning_resource_url': 'https://dart.dev',
          'notes':
              'Language syntax, async/await, streams, null safety, and isolate workers.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'React',
          'category': 'Web Development',
          'proficiency_level': 'Intermediate',
          'progress_percentage': 70.0,
          'date_started':
              now.subtract(const Duration(days: 120)).toIso8601String(),
          'target_completion_date':
              now.add(const Duration(days: 20)).toIso8601String(),
          'learning_resource_url': 'https://react.dev',
          'notes':
              'Hooks, state management, component lifecycle, and responsive styling.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ];

      for (final s in skillsData) {
        await txn.insert('skills', s);
      }

      // 3. Certifications (Matching design mockup Screen 7 & 8)
      final certsData = [
        {
          'name': 'Java Programming',
          'issuing_organization': 'Infosys',
          'category': 'Technical',
          'completion_date': '2024-03-15',
          'expiration_date': null,
          'credential_id': 'INF-JP-2024-88',
          'verification_url': 'https://infosys.com/verify',
          'description':
              'Comprehensive Java OOP, collections framework, multi-threading, and backend fundamentals.',
          'created_at': now.toIso8601String(),
        },
        {
          'name': 'Python for Beginners',
          'issuing_organization': 'Coursera',
          'category': 'Technical',
          'completion_date': '2024-01-20',
          'expiration_date': null,
          'credential_id': 'AB0223456',
          'verification_url': 'https://coursera.org/verify/AB0223456',
          'description':
              'Complete the Python for Beginners course, covering basic syntax, data structures and object-oriented programming.',
          'created_at': now.toIso8601String(),
        },
        {
          'name': 'Flutter Development',
          'issuing_organization': 'Google',
          'category': 'Technical',
          'completion_date': '2023-11-10',
          'expiration_date': null,
          'credential_id': 'GGL-FL-74921',
          'verification_url': 'https://developers.google.com/certification',
          'description':
              'Building modern cross-platform mobile apps using Flutter SDK and Dart.',
          'created_at': now.toIso8601String(),
        },
        {
          'name': 'Web Development',
          'issuing_organization': 'Udemy',
          'category': 'Professional',
          'completion_date': '2023-09-05',
          'expiration_date': null,
          'credential_id': 'UDM-WD-382910',
          'verification_url': 'https://udemy.com/certificate/UC-382910',
          'description':
              'Full-stack modern web development covering HTML5, CSS3, JavaScript ES6+, and responsive UI.',
          'created_at': now.toIso8601String(),
        },
      ];

      for (final c in certsData) {
        await txn.insert('certificates', c);
      }

      // 4. Projects (Matching design mockup Screen 9)
      final projectsData = [
        {
          'name': 'Student Portfolio Website',
          'short_description':
              'Responsive web development portfolio showcase.',
          'detailed_description':
              'A modern web development portfolio showcasing student academic and personal projects, skills, and interactive resume viewer.',
          'category': 'Web Development',
          'technologies': 'Flutter, Firebase',
          'status': 'Completed',
          'start_date': '2024-01-15',
          'completion_date': '2024-03-20',
          'github_url': 'https://github.com/priya/portfolio',
          'live_demo_url': 'https://priyasharma.dev',
          'key_features':
              '1. Interactive project gallery\n2. Responsive layout for mobile and desktop\n3. Contact form with email notification',
          'problems_solved':
              'Created a centralized professional web presence for technical campus placement season.',
          'what_learned':
              'Responsive web styling, Firebase hosting, and SEO optimization.',
          'notes':
              'Used as primary portfolio for software engineering internship applications.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'Task Manager App',
          'short_description':
              'Offline task and productivity tracking mobile app.',
          'detailed_description':
              'A cross-platform mobile app that enables students to organize daily assignments, deadline reminders, and prioritized goals.',
          'category': 'Mobile Development',
          'technologies': 'Flutter, Dart',
          'status': 'In Progress',
          'start_date': '2024-04-01',
          'completion_date': null,
          'github_url': 'https://github.com/priya/task-manager',
          'live_demo_url': null,
          'key_features':
              '1. Priority filtering (High, Medium, Low)\n2. Local SQLite persistence\n3. Category tags and search',
          'problems_solved':
              'Helps students keep track of concurrent assignment deadlines and academic schedules.',
          'what_learned':
              'Flutter stateful widgets, SQLite CRUD transactions, and local notifications.',
          'notes': 'Adding calendar sync in the next release.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'Movie Recommendation',
          'short_description':
              'Machine learning powered movie recommendation engine.',
          'detailed_description':
              'Content-based and collaborative filtering movie recommendation engine analyzing user preferences and genres.',
          'category': 'Artificial Intelligence and Machine Learning',
          'technologies': 'Python, ML',
          'status': 'Planned',
          'start_date': '2024-06-01',
          'completion_date': null,
          'github_url': 'https://github.com/priya/movie-recommendation',
          'live_demo_url': null,
          'key_features':
              '1. TF-IDF vectorization\n2. Cosine similarity ranking\n3. Interactive web UI',
          'problems_solved':
              'Provides personalized content suggestions using sparse matrix similarity scores.',
          'what_learned':
              'NumPy, Pandas, Scikit-learn, and vector cosine mathematics.',
          'notes': 'Planned for submission in 7th semester elective course.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'name': 'E-commerce Website',
          'short_description':
              'Full-stack responsive store with cart and checkout.',
          'detailed_description':
              'An end-to-end full stack web application featuring product catalog, search filters, shopping cart, and mock payment gateway.',
          'category': 'Web Development',
          'technologies': 'React, Node.js',
          'status': 'Completed',
          'start_date': '2023-09-10',
          'completion_date': '2023-12-15',
          'github_url': 'https://github.com/priya/ecommerce-store',
          'live_demo_url': 'https://priya-store.demo.app',
          'key_features':
              '1. Dynamic shopping cart state\n2. Filter by category, price, and ratings\n3. Responsive grid layout',
          'problems_solved':
              'Handled state synchronization across disparate components with Redux/Context API.',
          'what_learned':
              'Full stack REST API design, JWT auth, and responsive UI with React.',
          'notes': 'Completed as web development capstone project.',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ];

      for (final p in projectsData) {
        await txn.insert('projects', p);
      }

      // 5. Tasks (Matching design mockup Screen 10)
      final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
      final tomorrowStr = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1))
          .toIso8601String();
      final in3DaysStr = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 3))
          .toIso8601String();
      final in6DaysStr = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 6))
          .toIso8601String();
      final in8DaysStr = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 8))
          .toIso8601String();

      final tasksData = [
        {
          'title': 'Complete DSA problems',
          'description':
              'Solve Binary Search and Two Pointer problems on LeetCode.',
          'category': 'Coding Practice',
          'priority': 'High',
          'creation_date': now.toIso8601String(),
          'due_date': todayStr,
          'is_completed': 0,
        },
        {
          'title': 'Study DBMS',
          'description':
              'Review Normalization (1NF, 2NF, 3NF, BCNF) and indexing concepts.',
          'category': 'Technical Skills',
          'priority': 'Medium',
          'creation_date': now.toIso8601String(),
          'due_date': tomorrowStr,
          'is_completed': 0,
        },
        {
          'title': 'Build project feature',
          'description':
              'Implement SQLite local caching and responsive details page in Task Manager.',
          'category': 'Project Development',
          'priority': 'High',
          'creation_date': now.toIso8601String(),
          'due_date': in3DaysStr,
          'is_completed': 0,
        },
        {
          'title': 'Prepare for mock interview',
          'description':
              'Practice behavioral questions and Core CS fundamentals with peer group.',
          'category': 'Placement Preparation',
          'priority': 'Medium',
          'creation_date': now.toIso8601String(),
          'due_date': in6DaysStr,
          'is_completed': 0,
        },
        {
          'title': 'Revise OOP concepts',
          'description':
              'Inheritance, Polymorphism, Encapsulation, Abstraction, and SOLID principles.',
          'category': 'Computer Science Fundamentals',
          'priority': 'Low',
          'creation_date': now.toIso8601String(),
          'due_date': in8DaysStr,
          'is_completed': 0,
        },
      ];

      for (final t in tasksData) {
        await txn.insert('tasks', t);
      }

      // 6. Learning Goals
      await txn.insert('learning_goals', {
        'title': 'Solve 5 DSA Problems Daily',
        'goal_type': 'Daily',
        'target_count': 5,
        'current_count': 3,
        'is_completed': 0,
        'created_at': now.toIso8601String(),
        'target_date': todayStr,
      });

      await txn.insert('learning_goals', {
        'title': 'Complete 2 Full Mock Technical Interviews',
        'goal_type': 'Weekly',
        'target_count': 2,
        'current_count': 2,
        'is_completed': 1,
        'created_at': now.toIso8601String(),
        'target_date': in3DaysStr,
      });

      // 7. Placement Topics (Coding: 12/20 completed matching Screen 11)
      final codingTopics = [
        {'topic': 'Arrays & Two Pointers', 'solved': 35, 'att': 38, 'diff': 'Easy', 'status': 'Completed'},
        {'topic': 'Strings & Sliding Window', 'solved': 28, 'att': 30, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Linked Lists', 'solved': 22, 'att': 24, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Stacks and Queues', 'solved': 18, 'att': 20, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Searching and Sorting', 'solved': 25, 'att': 25, 'diff': 'Easy', 'status': 'Completed'},
        {'topic': 'Hashing & HashMaps', 'solved': 20, 'att': 22, 'diff': 'Easy', 'status': 'Completed'},
        {'topic': 'Binary Trees & BST', 'solved': 30, 'att': 35, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Heaps & Priority Queues', 'solved': 18, 'att': 20, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Greedy Algorithms', 'solved': 16, 'att': 18, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Bit Manipulation', 'solved': 14, 'att': 16, 'diff': 'Easy', 'status': 'Completed'},
        {'topic': 'Backtracking Patterns', 'solved': 15, 'att': 18, 'diff': 'Medium', 'status': 'Completed'},
        {'topic': 'Time and Space Complexity Analysis', 'solved': 15, 'att': 15, 'diff': 'Easy', 'status': 'Completed'},
        {'topic': 'Recursion Fundamentals', 'solved': 12, 'att': 18, 'diff': 'Medium', 'status': 'In Progress'},
        {'topic': 'Graphs (BFS, DFS, Dijkstra)', 'solved': 19, 'att': 28, 'diff': 'Hard', 'status': 'In Progress'},
        {'topic': 'Dynamic Programming 1D & 2D', 'solved': 14, 'att': 32, 'diff': 'Hard', 'status': 'Needs Revision'},
        {'topic': 'Disjoint Set Union (Union-Find)', 'solved': 8, 'att': 14, 'diff': 'Medium', 'status': 'In Progress'},
        {'topic': 'Tries & String Matching', 'solved': 6, 'att': 12, 'diff': 'Hard', 'status': 'Needs Revision'},
        {'topic': 'Monotonic Stacks & Queues', 'solved': 10, 'att': 15, 'diff': 'Medium', 'status': 'In Progress'},
        {'topic': 'Topological Sort & DAG', 'solved': 8, 'att': 12, 'diff': 'Medium', 'status': 'In Progress'},
        {'topic': 'Segment Trees & Fenwick Trees', 'solved': 4, 'att': 10, 'diff': 'Hard', 'status': 'Needs Revision'},
      ];

      for (final ct in codingTopics) {
        await txn.insert('placement_topics', {
          'track': 'Coding',
          'topic_name': ct['topic'],
          'category': 'DSA',
          'problems_solved': ct['solved'],
          'problems_attempted': ct['att'],
          'practice_links': 'https://leetcode.com',
          'notes': 'Completed standard NeetCode / Striver SDE sheet patterns.',
          'difficulty_level': ct['diff'],
          'completion_status': ct['status'],
          'updated_at': now.toIso8601String(),
        });
      }

      final coreCsTopics = [
        {'topic': 'Database Management Systems (DBMS)', 'status': 'Completed'},
        {'topic': 'Operating Systems (OS)', 'status': 'Completed'},
        {'topic': 'Computer Networks (CN)', 'status': 'In Progress'},
        {'topic': 'Object-Oriented Programming (OOP)', 'status': 'Completed'},
        {'topic': 'Software Engineering & Agile', 'status': 'Completed'},
        {'topic': 'Computer Architecture', 'status': 'Needs Revision'},
        {'topic': 'Structured Query Language (SQL)', 'status': 'Completed'},
      ];

      for (final cs in coreCsTopics) {
        await txn.insert('placement_topics', {
          'track': 'CoreCS',
          'topic_name': cs['topic'],
          'category': 'Computer Science',
          'problems_solved': cs['status'] == 'Completed' ? 10 : 5,
          'problems_attempted': 10,
          'notes':
              'Key definitions, normal forms, memory management, TCP/IP handshake reviewed.',
          'difficulty_level': 'Comprehensive',
          'completion_status': cs['status'],
          'updated_at': now.toIso8601String(),
        });
      }

      // Aptitude Topics (10/15 completed matching Screen 11)
      final aptitudeTopics = [
        {'topic': 'Percentages & Ratios', 'status': 'Completed', 'solved': 40, 'att': 42},
        {'topic': 'Profit, Loss & Discount', 'status': 'Completed', 'solved': 35, 'att': 38},
        {'topic': 'Simple & Compound Interest', 'status': 'Completed', 'solved': 30, 'att': 32},
        {'topic': 'Time, Speed & Distance', 'status': 'Completed', 'solved': 28, 'att': 30},
        {'topic': 'Time & Work', 'status': 'Completed', 'solved': 32, 'att': 35},
        {'topic': 'Permutations & Combinations', 'status': 'Completed', 'solved': 25, 'att': 28},
        {'topic': 'Probability & Statistics', 'status': 'Completed', 'solved': 24, 'att': 26},
        {'topic': 'Blood Relations', 'status': 'Completed', 'solved': 30, 'att': 30},
        {'topic': 'Syllogisms & Venn Diagrams', 'status': 'Completed', 'solved': 35, 'att': 36},
        {'topic': 'Coding & Decoding', 'status': 'Completed', 'solved': 40, 'att': 40},
        {'topic': 'Number & Letter Series', 'status': 'In Progress', 'solved': 18, 'att': 25},
        {'topic': 'Direction Sense & Seating', 'status': 'In Progress', 'solved': 15, 'att': 22},
        {'topic': 'Reading Comprehension', 'status': 'In Progress', 'solved': 20, 'att': 25},
        {'topic': 'Sentence Correction & Grammar', 'status': 'Needs Revision', 'solved': 12, 'att': 20},
        {'topic': 'Data Interpretation & Charts', 'status': 'Needs Revision', 'solved': 10, 'att': 18},
      ];

      for (final ap in aptitudeTopics) {
        await txn.insert('placement_topics', {
          'track': 'Aptitude',
          'topic_name': ap['topic'],
          'category': 'Aptitude',
          'problems_solved': ap['solved'],
          'problems_attempted': ap['att'],
          'notes':
              'Practiced speed math, syllogisms, blood relations, and sentence correction.',
          'difficulty_level': 'Medium',
          'completion_status': ap['status'],
          'updated_at': now.toIso8601String(),
        });
      }

      // 8. Interview Questions Bank
      final interviewQuestions = [
        {
          'category': 'Technical',
          'question':
              'Explain the difference between Processes and Threads. What is Context Switching?',
          'answer':
              'A process is an executing program instance with its own virtual memory space and resources. A thread is a lightweight unit of execution within a process that shares the heap, global memory, and open file descriptors. Context switching saves the execution state (CPU registers, program counter) of a thread/process so another can execute.',
          'status': 'Completed',
        },
        {
          'category': 'Technical',
          'question':
              'What are ACID properties in DBMS and why are they critical?',
          'answer':
              'Atomicity (all or nothing), Consistency (preserves database integrity constraints), Isolation (concurrent transactions execute without interference), and Durability (committed changes persist despite system crashes).',
          'status': 'Completed',
        },
        {
          'category': 'Technical',
          'question':
              'How does Flutter render UI widgets to the canvas using Skia/Impeller?',
          'answer':
              'Flutter controls every pixel on screen by compiling Dart code down to native machine code. It constructs a 3-tree architecture: Widget Tree (declarative configuration), Element Tree (instantiated lifecycle/state node), and RenderObject Tree (measures, layouts, and paints to GPU surface via Impeller).',
          'status': 'Completed',
        },
        {
          'category': 'HR',
          'question': 'Tell me about yourself (Self-Introduction).',
          'answer':
              'I am a final-year Computer Science student passionate about building performant mobile and web systems. Over the past 3 years, I have strengthened my core CS foundations, solved 280+ algorithm problems, and developed production-ready Flutter applications like SkillTrack. I thrive in collaborative agile teams where I can solve real user challenges.',
          'status': 'Completed',
        },
        {
          'category': 'HR',
          'question':
              'Describe a difficult engineering challenge you faced in a project and how you resolved it.',
          'answer':
              'During the development of SkillTrack, generating multi-page PDF documents without blocking the main UI thread caused minor frame drops on lower-end Android devices. I resolved this by offloading heavy data aggregation and PDF drawing calculations to background Dart isolates, reducing UI frame latency from 45ms down to 8ms.',
          'status': 'In Progress',
        },
        {
          'category': 'HR',
          'question': 'Why do you want to join our engineering organization?',
          'answer':
              'Your company works on large-scale distributed systems that impact millions of users daily. I am seeking a high-caliber engineering culture where code quality, mentorship, and continuous learning are prioritized.',
          'status': 'Needs Revision',
        },
      ];

      for (final iq in interviewQuestions) {
        await txn.insert('interview_questions', {
          'category': iq['category'],
          'question': iq['question'],
          'answer': iq['answer'],
          'status': iq['status'],
          'updated_at': now.toIso8601String(),
        });
      }

      // 9. Job Applications (Matching Screen 11: TCS Upcoming Interview)
      final jobApps = [
        {
          'company_name': 'TCS',
          'role': 'Software Engineer',
          'application_date': '2026-04-15',
          'application_deadline': '2026-05-15',
          'status': 'Interview',
          'job_description_url': 'https://www.tcs.com/careers',
          'required_skills': 'Java, Python, DSA, SQL',
          'interview_date': 'May 30, 2026',
          'notes': 'Upcoming Technical & HR Interview scheduled.',
          'updated_at': now.toIso8601String(),
        },
        {
          'company_name': 'Google India',
          'role': 'Associate Software Engineer (Flutter / Mobile)',
          'application_date': '2026-09-15',
          'application_deadline': '2026-10-31',
          'status': 'Interview',
          'job_description_url': 'https://careers.google.com/jobs',
          'required_skills':
              'Dart, Flutter, Data Structures, OOP, System Design',
          'interview_date': now.add(const Duration(days: 4)).toIso8601String(),
          'notes':
              'Technical Round 1 scheduled: Live coding in DSA and Android architecture review.',
          'updated_at': now.toIso8601String(),
        },
        {
          'company_name': 'Microsoft IDC',
          'role': 'Software Development Engineer - I',
          'application_date': '2026-09-20',
          'application_deadline': '2026-11-05',
          'status': 'Assessment',
          'job_description_url': 'https://careers.microsoft.com',
          'required_skills': 'C++, Java, Algorithms, Distributed Caching',
          'interview_date': null,
          'notes':
              'Cleared Online Coding Assessment (100% test cases). Awaiting round shortlist.',
          'updated_at': now.toIso8601String(),
        },
        {
          'company_name': 'Goldman Sachs',
          'role': 'Summer Technology Analyst',
          'application_date': '2026-10-01',
          'application_deadline':
              now.add(const Duration(days: 3)).toIso8601String(),
          'status': 'Applied',
          'job_description_url': 'https://goldmansachs.com/careers',
          'required_skills': 'Python, SQL, Financial Engineering, Algorithms',
          'interview_date': null,
          'notes': 'Application submitted via university placement cell.',
          'updated_at': now.toIso8601String(),
        },
        {
          'company_name': 'Amazon AWS',
          'role': 'Cloud Support Associate',
          'application_date': '2026-08-10',
          'application_deadline': '2026-09-01',
          'status': 'Selected',
          'job_description_url': 'https://amazon.jobs',
          'required_skills':
              'Linux, Cloud Infrastructure, Networking, Shell Scripting',
          'interview_date': '2026-09-10',
          'notes': 'Received official pre-placement offer letter!',
          'updated_at': now.toIso8601String(),
        },
      ];

      for (final ja in jobApps) {
        await txn.insert('job_applications', ja);
      }

      // 10. Education
      await txn.insert('education', {
        'institution': 'National Institute of Technology',
        'degree': 'Bachelor of Technology',
        'field_of_study': 'Computer Science & Engineering',
        'start_year': '2022',
        'end_year': '2026',
        'grade_or_cgpa': '8.92 / 10.0 CGPA',
        'created_at': now.toIso8601String(),
      });

      await txn.insert('education', {
        'institution': 'St. Joseph Higher Secondary School',
        'degree': 'Central Board (Class XII)',
        'field_of_study': 'Physics, Chemistry, Mathematics & CS',
        'start_year': '2020',
        'end_year': '2022',
        'grade_or_cgpa': '96.4%',
        'created_at': now.toIso8601String(),
      });

      // 11. Achievements
      await txn.insert('achievements', {
        'title': 'Rank 42 / 14,000 in National Collegiate Coding Championship',
        'description':
            'Solved 6 algorithmic problems in under 90 minutes using dynamic programming and graph structures.',
        'date_achieved': '2026-04-12',
        'created_at': now.toIso8601String(),
      });

      await txn.insert('achievements', {
        'title': '2nd Runner-up at Smart India Internal University Hackathon',
        'description':
            'Built an AI-assisted hospital triage routing system in 36 continuous hours.',
        'date_achieved': '2025-10-28',
        'created_at': now.toIso8601String(),
      });
    });
  }
}
