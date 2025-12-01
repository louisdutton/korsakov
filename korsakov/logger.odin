package korsakov

import "core:log"
import "core:os"

LOG_FILE :: "korsakov.log"

create_logger :: proc() -> log.Logger {
  if !os.exists(LOG_FILE) {os.write_entire_file(LOG_FILE, {})}
  fd, _ := os.open(LOG_FILE, os.O_WRONLY | os.O_SYNC)
  return log.create_file_logger(
    fd,
    .Debug when ODIN_DEBUG else .Info,
    {.Level},
  )
}

destroy_logger :: proc() {
  log.destroy_file_logger(context.logger)
}
