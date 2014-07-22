describe Bosh::Workspace::StemcellHelper do
  class StemcellHelperTester
    include Bosh::Workspace::StemcellHelper

    attr_reader :director, :work_dir

    def initialize(director, work_dir)
      @director = director
      @work_dir = work_dir
    end
  end

  subject { stemcell_helper }
  let(:stemcell_helper) { StemcellHelperTester.new(director, work_dir) }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }
  let(:work_dir) { asset_dir("manifests-repo") }

  context "with stemcell command" do
    let(:stemcell_cmd) { instance_double("Bosh::Cli::Command::Stemcell") }
    before { Bosh::Cli::Command::Stemcell.stub(:new).and_return(stemcell_cmd) }

    describe "#stemcell_download" do
      let(:name) { "foo" }
      subject { stemcell_helper.stemcell_download(name) }
      
      it "downloads stemcell" do
        Dir.should_receive(:chdir).and_yield
        stemcell_cmd.should_receive(:download_public).with(name)
        subject
      end
    end

    describe "#stemcell_upload" do
      let(:file) { "foo.tgz" }
      subject { stemcell_helper.stemcell_upload(file) }
      
      it "uploads stemcell" do
        stemcell_cmd.should_receive(:upload).with(file)
        subject
      end
    end
  end

  describe "#stemcell_uploaded?" do
    let(:stemcells) { [{ "name" => "foo", "version" => "1" }] }
    subject { stemcell_helper.stemcell_uploaded?(name, 1) }
    before { director.should_receive(:list_stemcells).and_return(stemcells) }

    context "stemcell exists" do
      let(:name) { "foo" }
      it { should be_true }
    end

    context "stemcell not found" do
      let(:name) { "bar" }
      it { should be_false }
    end
  end
  
  describe "#stemcell_dir" do
    let(:stemcells_dir) { File.join(work_dir, ".stemcells") }
    subject { stemcell_helper.stemcells_dir }
    
    before { FileUtils.should_receive(:mkdir_p).once.with(stemcells_dir).and_return([stemcells_dir]) }

    it { should eq stemcells_dir }

    it "memoizes" do
      subject
      expect(subject).to eq stemcells_dir
    end
  end

  describe "#project_deployment_stemcells" do
    subject { stemcell_helper.project_deployment_stemcells }
    let(:stemcell) { instance_double("Bosh::Workspace::Stemcell") }
    let(:stemcell_data) { { name: "foo" } }
    let(:stemcells) { [stemcell_data, stemcell_data] }

    before { stemcell_helper.stub_chain("project_deployment.stemcells").and_return(stemcells) }

    it "inits stemcells once" do
      Bosh::Workspace::Stemcell.should_receive(:new).twice
        .with(stemcell_data, /\/.stemcells/).and_return(stemcell)
      subject
      expect(subject).to eq [stemcell, stemcell]
    end
  end
end