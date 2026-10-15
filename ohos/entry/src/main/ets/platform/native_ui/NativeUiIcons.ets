// OHOS system symbols; SF Symbol names stay on the shared/iOS side of the bridge.
export function nativeDockIcon(id: string, selected: boolean = false): Resource {
  switch (id) {
    case 'course': case 'graduate_schedule_import':
      return selected ? $r('sys.symbol.book_pages_fill') : $r('sys.symbol.book_pages');
    case 'campus': case 'graduate':
      return selected ? $r('sys.symbol.graduationcap_fill') : $r('sys.symbol.graduationcap');
    case 'profile': return selected ? $r('sys.symbol.person_fill') : $r('sys.symbol.person');
    case 'grades': case 'graduate_grades':
      return selected ? $r('sys.symbol.ranking_fill') : $r('sys.symbol.ranking');
    case 'ccyl': return selected ? $r('sys.symbol.star_fill') : $r('sys.symbol.star');
    case 'plan_completion': case 'thesis_progress':
      return selected ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.checkmark_circle');
    case 'train_program': case 'graduate_train_plan':
      return selected ? $r('sys.symbol.list_bullet_square_fill') : $r('sys.symbol.list_bullet_square');
    case 'classroom': return selected ? $r('sys.symbol.house_fill') : $r('sys.symbol.house');
    case 'network_device':
      return selected ? $r('sys.symbol.wifi_router_fill') : $r('sys.symbol.wifi_router');
    case 'passpoint': return $r('sys.symbol.wifi');
    case 'balance_query': return selected ? $r('sys.symbol.bolt_fill') : $r('sys.symbol.bolt');
    case 'academic_calendar':
      return selected ? $r('sys.symbol.calendar_fill') : $r('sys.symbol.calendar');
    case 'fitness_test': return $r('sys.symbol.figure_run');
    case 'notice': return selected ? $r('sys.symbol.bell_fill') : $r('sys.symbol.bell');
    case 'downloaded_attachments': return selected ? $r('sys.symbol.folder_fill') : $r('sys.symbol.folder');
    case 'class_schedule_inquiry': return $r('sys.symbol.magnifyingglass');
    case 'course_curriculum': return $r('sys.symbol.book_closed_right_left');
    case 'exam_plan': return selected ? $r('sys.symbol.doc_text_fill') : $r('sys.symbol.doc_text');
    case 'zysc': return selected ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart');
    case 'leave': case 'lab_attendance': case 'mentor_tasks':
      return selected ? $r('sys.symbol.checkmark_clipboard_fill') : $r('sys.symbol.checkmark_clipboard');
    case 'repair': return $r('sys.symbol.wrench_and_screwdriver');
    case '__native_more__': return $r('sys.symbol.more');
    default: return $r('sys.symbol.square_grid_2x2');
  }
}

export function nativeControlIcon(symbol: string): Resource {
  switch (symbol) {
    case 'checkmark': return $r('sys.symbol.checkmark');
    case 'arrow.clockwise': return $r('sys.symbol.arrow_clockwise');
    case 'arrow.counterclockwise': return $r('sys.symbol.arrow_counterclockwise');
    case 'photo': return $r('sys.symbol.picture');
    case 'crop': return $r('sys.symbol.crop');
    case 'trash': return $r('sys.symbol.trash');
    case 'rectangle.portrait.and.arrow.right': return $r('sys.symbol.arrow_right_and_square');
    default: return symbol.startsWith('person') ? $r('sys.symbol.person') :
      $r('sys.symbol.square_grid_2x2');
  }
}
