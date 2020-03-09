require_relative "../test_base"

class TransactionTests < TestBase
  ###########################################################################################
  #Transactions Test Case 1: Retrieve list of transactions for user without a card
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #
  #	Steps:
  #		1. Retrieve transactions (passing in user_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 200
  #		- count = 0
  ###########################################################################################
  test "transactions: user without card" do
    user_token = 'TestUser' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})

    # Attempt to list transactions
    response = Transactions::list_transactions({:user_token => user_token})
    response_body = JSON.parse(response.body) if response.body

    pp response_body
    # Verify response
    assert_equal('200', response.code, 'Expected list_transactions to succeed')
    assert_equal(0, response_body['count'], 'Expected 0 transactions')
  end

  ###########################################################################################
  #Transactions Test Case 2: Retrieve list of transactions for user with a card and simulated transactions
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #		3. Create a Funding source
  #		4. Create a GPA Order (passing in user_token from user and funding_source_token from funding source)
  #		5. Create active Card (passing in user_token from user and card_product_token from card product)
  #		6. Simulate 1 financial (passing in token from card)
  #
  #	Steps:
  #		1. Retrieve transactions (passing in user_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 200
  #		- count = 2
  ###########################################################################################
  test "transactions: listing 1 transaction" do
    token = 'Card' + Time.now().to_f.to_s
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s
    funding_source_token = 'TestFS' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})

    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:card_life_cycle => {:activate_upon_issue => true}, :fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    resp = Cards::create_card({
      :token => token,
      :user_token => user_token,
      :card_product_token => card_product_token,
      :show_pan => true, :show_cvv_number => true})
    resp = JSON.parse(resp.body)

    FundingSources::create_funding_source({:token => funding_source_token, :name => "My funding source"})

    Cards::create_card({:token => token, :user_token => user_token, :card_product_token => card_product_token})

    GpaOrder::create_gpa_order({
      :user_token => user_token,
      :amount => '1000',
      :currency_code => 'USD',
      :funding_source_token => funding_source_token}).body

    Simulate::simulate_financial({:card_token => token, :amount => 2.34, :mid => "WizardsOfTheCoast"}).body

    # Attempt to list transactions
    response = Transactions::list_transactions({:user_token => user_token})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal('200', response.code, 'Expected list_transactions to succeed')
    assert_equal(2, response_body["count"], 'Expected 2 transactions')
  end
end