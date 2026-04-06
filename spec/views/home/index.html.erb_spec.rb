require 'rails_helper'

RSpec.describe 'home/index.html.erb', type: :view do
  it 'renders the landing title' do
    render

    expect(rendered).to include('Research Goal')
  end
end
