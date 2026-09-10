// MIT Fall 2026, verified 2026-09-09 against the official Registrar calendar:
// https://registrar.mit.edu/calendar-pdf
// https://registrar.mit.edu/calendar/class-days
// Classes: Sep 9-Dec 10. Tue/Thu course: 12 Tuesdays + 13 Thursdays.
// Oct 13 uses a Monday schedule; Nov 26 is Thanksgiving. Nov 11 is a
// Wednesday holiday and does not remove a Tuesday/Thursday class slot.
#import "gabri-schedule.typ": no-class

#let class-dates = (
  "2026-09-10",
  "2026-09-15",
  "2026-09-17",
  "2026-09-22",
  "2026-09-24",
  "2026-09-29",
  "2026-10-01",
  "2026-10-06",
  "2026-10-08",
  "2026-10-15",
  "2026-10-20",
  "2026-10-22",
  "2026-10-27",
  "2026-10-29",
  "2026-11-03",
  "2026-11-05",
  "2026-11-10",
  "2026-11-12",
  "2026-11-17",
  "2026-11-19",
  "2026-11-24",
  "2026-12-01",
  "2026-12-03",
  "2026-12-08",
  "2026-12-10",
)

// Fixed calendar exceptions remain on these dates when lectures move.
#let calendar-exceptions = (
  no-class(on: "2026-10-13", description: [MIT follows a Monday schedule.]),
  no-class(on: "2026-11-26", description: [Thanksgiving holiday.]),
)
