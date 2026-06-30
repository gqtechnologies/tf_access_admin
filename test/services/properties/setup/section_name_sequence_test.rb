# frozen_string_literal: true

require "test_helper"

# Single source of truth for "prefix + suffix" section naming, shared by the
# quick engine and the manual builder batch (wizard-manual-structure-builder).
class Properties::Setup::SectionNameSequenceTest < ActiveSupport::TestCase
  Sequence = Properties::Setup::SectionNameSequence

  test "generates letter-suffixed names" do
    assert_equal %w[Torre\ A Torre\ B Torre\ C],
                 Sequence.names(prefix: "Torre", suffix_type: :letter, count: 3)
  end

  test "generates number-suffixed names" do
    assert_equal [ "Piso 1", "Piso 2" ],
                 Sequence.names(prefix: "Piso", suffix_type: :number, count: 2)
  end

  test "name returns a single zero-based entry" do
    assert_equal "Torre A", Sequence.name(prefix: "Torre", suffix_type: :letter, index: 0)
    assert_equal "Piso 3", Sequence.name(prefix: "Piso", suffix_type: :number, index: 2)
  end

  test "blank prefix yields the bare suffix" do
    assert_equal "A", Sequence.name(prefix: "", suffix_type: :letter, index: 0)
  end

  test "non-positive count yields an empty list" do
    assert_empty Sequence.names(prefix: "Torre", suffix_type: :letter, count: 0)
  end
end
