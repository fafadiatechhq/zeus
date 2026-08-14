import '../models/user.dart';
import '../models/attendance.dart';
import '../models/task.dart';
import '../models/expense.dart';

class MockData {
  // Current logged-in user
  static const currentUser = User(
    id: 'user_001',
    name: 'Rajesh Kumar',
    email: 'rajesh.kumar@company.com',
    phone: '+91 98765 43210',
    role: 'Field Sales Executive',
    department: 'Sales',
    avatarInitials: 'RK',
  );

  // Team members (for manager view)
  static const List<User> teamMembers = [
    User(
      id: 'user_002',
      name: 'Priya Sharma',
      email: 'priya.sharma@company.com',
      phone: '+91 98765 11111',
      role: 'Field Sales Executive',
      department: 'Sales',
      avatarInitials: 'PS',
    ),
    User(
      id: 'user_003',
      name: 'Amit Patel',
      email: 'amit.patel@company.com',
      phone: '+91 98765 22222',
      role: 'Service Technician',
      department: 'Service',
      avatarInitials: 'AP',
    ),
    User(
      id: 'user_004',
      name: 'Sunita Nair',
      email: 'sunita.nair@company.com',
      phone: '+91 98765 33333',
      role: 'Delivery Agent',
      department: 'Logistics',
      avatarInitials: 'SN',
    ),
  ];

  // Today's attendance (initially not checked in)
  static AttendanceRecord todayAttendance = AttendanceRecord(
    id: 'att_today',
    userId: 'user_001',
    date: DateTime.now(),
    status: AttendanceStatus.notCheckedIn,
  );

  // Past attendance records
  static List<AttendanceRecord> attendanceHistory = [
    AttendanceRecord(
      id: 'att_001',
      userId: 'user_001',
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkInTime: DateTime.now().subtract(const Duration(days: 1, hours: 16)),
      checkInLocation: 'Andheri East, Mumbai',
      checkOutTime: DateTime.now().subtract(const Duration(days: 1, hours: 7)),
      checkOutLocation: 'Bandra West, Mumbai',
      status: AttendanceStatus.checkedOut,
    ),
    AttendanceRecord(
      id: 'att_002',
      userId: 'user_001',
      date: DateTime.now().subtract(const Duration(days: 2)),
      checkInTime: DateTime.now().subtract(const Duration(days: 2, hours: 15, minutes: 45)),
      checkInLocation: 'Powai, Mumbai',
      checkOutTime: DateTime.now().subtract(const Duration(days: 2, hours: 6, minutes: 30)),
      checkOutLocation: 'Powai, Mumbai',
      status: AttendanceStatus.checkedOut,
    ),
    AttendanceRecord(
      id: 'att_003',
      userId: 'user_001',
      date: DateTime.now().subtract(const Duration(days: 3)),
      status: AttendanceStatus.onLeave,
    ),
    AttendanceRecord(
      id: 'att_004',
      userId: 'user_001',
      date: DateTime.now().subtract(const Duration(days: 4)),
      checkInTime: DateTime.now().subtract(const Duration(days: 4, hours: 15, minutes: 10)),
      checkInLocation: 'Malad West, Mumbai',
      checkOutTime: DateTime.now().subtract(const Duration(days: 4, hours: 6, minutes: 55)),
      checkOutLocation: 'Malad West, Mumbai',
      status: AttendanceStatus.checkedOut,
    ),
  ];

  // Tasks
  static List<TaskItem> tasks = [
    TaskItem(
      id: 'task_001',
      title: 'Visit Infosys Mumbai Office',
      description:
          'Meet with the procurement team at Infosys to present the Q3 product catalog and negotiate annual contract renewal.',
      assigneeId: 'user_001',
      dueDate: DateTime.now().add(const Duration(hours: 3)),
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      linkedCustomer: 'Infosys Ltd.',
      linkedSite: 'Infosys Mumbai, BKC',
      requiresGeoVerification: true,
      checklist: [
        ChecklistItem(id: 'cl_1', label: 'Prepare product catalog', isDone: true),
        ChecklistItem(id: 'cl_2', label: 'Confirm meeting with Ravi Menon', isDone: true),
        ChecklistItem(id: 'cl_3', label: 'Present Q3 pricing', isDone: false),
        ChecklistItem(id: 'cl_4', label: 'Collect signed MOU', isDone: false),
      ],
    ),
    TaskItem(
      id: 'task_002',
      title: 'Follow-up with TCS Pune',
      description:
          'Follow up on the pending proposal sent last week. Resolve any technical queries from their IT team.',
      assigneeId: 'user_001',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.open,
      priority: TaskPriority.medium,
      linkedCustomer: 'TCS',
      linkedSite: 'TCS Pune, Hinjewadi',
      checklist: [
        ChecklistItem(id: 'cl_5', label: 'Call Anita Joshi (IT Head)', isDone: false),
        ChecklistItem(id: 'cl_6', label: 'Share updated proposal PDF', isDone: false),
      ],
    ),
    TaskItem(
      id: 'task_003',
      title: 'Retail Audit — Dadar Stores',
      description: 'Conduct audit of 5 retail stores in Dadar area. Check product placement, stock levels, and branding compliance.',
      assigneeId: 'user_001',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: TaskStatus.open,
      priority: TaskPriority.medium,
      linkedSite: 'Dadar, Mumbai',
      checklist: [
        ChecklistItem(id: 'cl_7', label: 'Store 1: Dadar TT', isDone: false),
        ChecklistItem(id: 'cl_8', label: 'Store 2: Shivaji Park', isDone: false),
        ChecklistItem(id: 'cl_9', label: 'Store 3: Plaza Cinema Road', isDone: false),
        ChecklistItem(id: 'cl_10', label: 'Store 4: Hindu Colony', isDone: false),
        ChecklistItem(id: 'cl_11', label: 'Store 5: Cadell Road', isDone: false),
      ],
    ),
    TaskItem(
      id: 'task_004',
      title: 'Service Call — HDFC Bank ATM',
      description: 'Scheduled maintenance of cash dispenser unit at HDFC Bank Goregaon branch.',
      assigneeId: 'user_001',
      dueDate: DateTime.now().subtract(const Duration(hours: 2)),
      status: TaskStatus.completed,
      priority: TaskPriority.urgent,
      linkedCustomer: 'HDFC Bank',
      linkedSite: 'HDFC Bank Goregaon Branch',
      requiresGeoVerification: true,
      completionNotes: 'Replaced the card reader module. Unit operational. Informed branch manager.',
      checklist: [
        ChecklistItem(id: 'cl_12', label: 'Diagnose issue', isDone: true),
        ChecklistItem(id: 'cl_13', label: 'Replace faulty component', isDone: true),
        ChecklistItem(id: 'cl_14', label: 'Test unit', isDone: true),
        ChecklistItem(id: 'cl_15', label: 'Get sign-off from branch', isDone: true),
      ],
    ),
    TaskItem(
      id: 'task_005',
      title: 'New Lead — Tata Motors Showroom',
      description: 'Visit prospective client at Tata Motors showroom for initial pitch on our fleet management solution.',
      assigneeId: 'user_001',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      status: TaskStatus.blocked,
      priority: TaskPriority.low,
      linkedCustomer: 'Tata Motors',
      linkedSite: 'Tata Motors Showroom, Thane',
    ),
  ];

  // Expenses
  static List<Expense> expenses = [
    Expense(
      id: 'exp_001',
      userId: 'user_001',
      title: 'Auto-rickshaw to Infosys BKC',
      category: ExpenseCategory.travel,
      amount: 120.0,
      date: DateTime.now(),
      status: ExpenseStatus.draft,
      linkedTaskId: 'task_001',
      notes: 'Meter fare',
    ),
    Expense(
      id: 'exp_002',
      userId: 'user_001',
      title: 'Client lunch — Infosys team',
      category: ExpenseCategory.food,
      amount: 1850.0,
      date: DateTime.now(),
      status: ExpenseStatus.submitted,
      linkedTaskId: 'task_001',
      notes: '3 people, restaurant near BKC',
      hasReceipt: true,
    ),
    Expense(
      id: 'exp_003',
      userId: 'user_001',
      title: 'Train ticket — Mumbai to Pune',
      category: ExpenseCategory.travel,
      amount: 340.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: ExpenseStatus.approved,
      linkedTaskId: 'task_002',
      hasReceipt: true,
    ),
    Expense(
      id: 'exp_004',
      userId: 'user_001',
      title: 'Mobile data top-up',
      category: ExpenseCategory.communication,
      amount: 299.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: ExpenseStatus.approved,
    ),
    Expense(
      id: 'exp_005',
      userId: 'user_001',
      title: 'Replacement cable for ATM unit',
      category: ExpenseCategory.equipment,
      amount: 650.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: ExpenseStatus.submitted,
      linkedTaskId: 'task_004',
      hasReceipt: true,
    ),
  ];

  // Dashboard stats
  static Map<String, int> get dashboardStats => {
    'tasksToday': tasks.where((t) => !_isOverdue(t) && t.status != TaskStatus.completed).length,
    'tasksCompleted': tasks.where((t) => t.status == TaskStatus.completed).length,
    'pendingExpenses': expenses.where((e) => e.status == ExpenseStatus.draft || e.status == ExpenseStatus.submitted).length,
    'attendanceDaysThisMonth': 18,
  };

  static bool _isOverdue(TaskItem task) {
    return task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
  }
}
