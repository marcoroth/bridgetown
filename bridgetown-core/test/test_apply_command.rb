# frozen_string_literal: true

require "helper"

class TestApplyCommand < BridgetownUnitTest
  context "the apply command" do
    setup do
      @cmd = Bridgetown::Commands::Apply.new
      File.delete("bridgetown.automation.rb") if File.exist?("bridgetown.automation.rb")
      @template = <<-TEMPLATE
        say_status :urltest, "Works!"
      TEMPLATE
      allow(@template).to receive(:read).and_return(@template)
    end

    should "automatically run bridgetown.automation.rb" do
      output = capture_stdout do
        @cmd.apply_automation
      end
      assert_match "add bridgetown.automation.rb", output

      File.open("bridgetown.automation.rb", "w") do |f|
        f.puts "say_status :applytest, 'I am Bridgetown. Hear me roar!'"
      end
      output = capture_stdout do
        @cmd.apply_automation
      end
      File.delete("bridgetown.automation.rb")
      assert_match %r!applytest.*?Hear me roar\!!, output
    end

    should "run automations via relative file paths" do
      file = "test/fixtures/test_automation.rb"
      output = capture_stdout do
        @cmd.invoke(:apply_automation, [file])
      end
      assert_match %r!fixture.*?Works\!!, output
    end

    should "run automations from URLs" do
      allow_any_instance_of(Bridgetown::Commands::Apply).to receive(:open).and_return(@template)
      file = "http://randomdomain.com/12345.rb"
      output = capture_stdout do
        @cmd.invoke(:apply_automation, [file])
      end
      assert_match %r!apply.*?http://randomdomain\.com/12345\.rb!, output
      assert_match %r!urltest.*?Works\!!, output
    end

    should "automatically add bridgetown.automation.rb to URL folder path" do
      allow_any_instance_of(Bridgetown::Commands::Apply).to receive(:open).and_return(@template)
      file = "http://randomdomain.com/foo"
      output = capture_stdout do
        @cmd.invoke(:apply_automation, [file])
      end
      assert_match %r!apply.*?http://randomdomain\.com/foo/bridgetown\.automation\.rb!, output
    end

    should "transform GitHub repo URLs automatically" do
      allow_any_instance_of(Bridgetown::Commands::Apply).to receive(:open).and_return(@template)
      file = "https://github.com/bridgetownrb/bridgetown-automations"
      output = capture_stdout do
        @cmd.invoke(:apply_automation, [file])
      end
      assert_match %r!apply.*?https://raw\.githubusercontent.com/bridgetownrb/bridgetown-automations/master/bridgetown\.automation\.rb!, output
      assert_match %r!urltest.*?Works\!!, output
    end

    should "transform Gist URLs automatically" do
      allow_any_instance_of(Bridgetown::Commands::Apply).to receive(:open).and_return(@template)
      file = "https://gist.github.com/jaredcwhite/963d40acab5f21b42152536ad6847575"
      allow_any_instance_of(Bridgetown::Commands::Apply).to receive(:open).and_return(@template)
      output = capture_stdout do
        @cmd.invoke(:apply_automation, [file])
      end
      assert_match %r!apply.*?https://gist\.githubusercontent.com/jaredcwhite/963d40acab5f21b42152536ad6847575/raw/bridgetown\.automation\.rb!, output
      assert_match %r!urltest.*?Works\!!, output
    end
  end
end
