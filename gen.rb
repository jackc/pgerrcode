# Run this script against the data in table A.1. on https://www.postgresql.org/docs/11/errcodes-appendix.html.
#
# Source data should be formatted like the following:
#
# Class 00 — Successful Completion
# 00000 	successful_completion
# Class 01 — Warning
# 01000 	warning
# 0100C 	dynamic_result_sets_returned
#
# for best results pass through gofmt
# ruby gen.rb < tablecontents.txt  | gofmt > errcode.go

code_name_overrides = {
  # Some error code names are repeated. In those cases add the error class as a suffix.
  "01004" => "StringDataRightTruncationWarning",
  "22001" => "StringDataRightTruncationDataException",
  "22004" => "NullValueNotAllowedDataException",
  "2F002" => "ModifyingSQLDataNotPermittedSQLRoutineException",
  "2F003" => "ProhibitedSQLStatementAttemptedSQLRoutineException",
  "2F004" => "ReadingSQLDataNotPermittedSQLRoutineException",
	"38002" => "ModifyingSQLDataNotPermittedExternalRoutineException",
	"38003" => "ProhibitedSQLStatementAttemptedExternalRoutineException",
  "38004" => "ReadingSQLDataNotPermittedExternalRoutineException",
  "39004" => "NullValueNotAllowedExternalRoutineInvocationException",

  # Go casing corrections
	"08001" => "SQLClientUnableToEstablishSQLConnection",
  "08004" => "SQLServerRejectedEstablishmentOfSQLConnection",
  "P0000" => "PLpgSQLError"
}

cls_errs = Array.new
cls_assertions = Array.new
last_cls = ""
last_cls_full = ""

puts "// Package pgerrcode contains constants for PostgreSQL error codes."
puts "package pgerrcode"
puts ""
puts "// Source: https://www.postgresql.org/docs/11/errcodes-appendix.html"
puts "// See gen.rb for script that can convert the error code table to Go code."
puts ""
puts "const ("

ARGF.each do |line|
  case line
  when /^Class/
    if cls_errs.length > 0 && last_cls != ""
      this_cls_errs = cls_errs.join(", ")
      assert_func = "// Is#{last_cls} asserts the error code class is #{last_cls_full}\n" \
       "func Is#{last_cls} (code string) bool {\n" \
       "    switch code{\n" \
       "        case #{this_cls_errs}:\n" \
       "            return true\n" \
       "    }\n" \
       "    return false\n" \
       "}\n"
       cls_assertions.push(assert_func)
    end
    last_cls = line.split("—")[1]
    .gsub(" ", "")
    .gsub("/", "")
    .gsub("\n", "")
    .sub(/\(\w*\)/, "")
    last_cls_full = line.gsub("\n", "")
    cls_errs.clear
    puts
    puts "// #{line}"
  when /^(\w{5})\s+(\w+)/
    code = $1
    name = code_name_overrides.fetch(code) do
      $2.split("_").map(&:capitalize).join
        .gsub("Sql", "SQL")
        .gsub("Xml", "XML")
        .gsub("Fdw", "FDW")
        .gsub("Srf", "SRF")
        .gsub("Io", "IO")
    end
    cls_errs.push(name)
    puts %Q[#{name} = "#{code}"]
  else
    puts line
  end
end
puts ")"
cls_assertions.each do |cls_assertion|
  puts cls_assertion
end