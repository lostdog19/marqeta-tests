require_relative "../test_base"

class CardCreationTests < TestBase
  ###########################################################################################
  # Create Card Test Case 1: Create valid card with minimal input
  # 	Prerequisites:
  # 		1. Create User (passing in token)
  # 		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  # 	Steps:
  # 		1. Create Card (passing in user_token from prereqs and card_product_token from prereqs)
  #
  # 	Expected:
  # 		- HTTP response 201
  # 		- user_token in response matches one passed in
  # 		- card_product_token in response matches one passed in
  # 		- expiration matches today's month and year+4 in the format 'MMYY' => '0324'
  # 		- pin_is_set is false
  # 		- state is 'UNACTIVATED'
  # 		- state_reason is 'New card'
  # 		- fulfillment_status is 'ISSUED'
  # 		- instrument_type is 'PHYSICAL_MSR'
  # 		- expedite is false
  ###########################################################################################
  test "create_card: Valid with minimal input" do
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("201", response.code, 'Expected create_card to succeed')
    assert_equal(user_token, response_body['user_token'], 'Expected user_token to match input')
    assert_equal(card_product_token, response_body['card_product_token'], 'Expected card_product_token to match input')
    assert_equal("#{Date.today.strftime('%m')+(Date.today.strftime('%y').to_i+4).to_s}", response_body['expiration'], 'Expected expiration to be 4 years from today')
    assert_false(response_body['pin_is_set'], 'Expected pin_is_set to be false')
    assert_equal('UNACTIVATED', response_body['state'], 'Expected state to be UNACTIVATED')
    assert_equal('New card', response_body['state_reason'], 'Expected state_reason to be New card')
    assert_equal('ISSUED', response_body['fulfillment_status'], 'Expected fulfillment_status to be ISSUED')
    assert_equal('PHYSICAL_MSR', response_body['instrument_type'], 'Expected instrument_type to be PHYSICAL_MSR')
    assert_false(response_body['expedite'], 'Expected expeditie to be false')
  end

  ###########################################################################################
  # Create Card Test Case 2: Verify idempotency
  # 	Prerequisites:
  # 		1. Create User (passing in token)
  # 		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  # 	Steps:
  # 		1. Create Card (passing in token, user_token from prereqs, card_product_token from prereqs)
  # 		2. Repeat step 1
  #
  # 	Expected:
  # 		- HTTP response 201
  # 		- user_token in response matches one passed in
  # 		- card_product_token in response matches one passed in
  # 		- expiration matches today's month and year+4 in the format 'MMYY' => '0324'
  # 		- pin_is_set is false
  # 		- state is 'UNACTIVATED'
  # 		- state_reason is 'New card'
  # 		- fulfillment_status is 'ISSUED'
  # 		- instrument_type is 'PHYSICAL_MSR'
  # 		- expedite is false
  ###########################################################################################
  test "create_card: Verify idempotency" do
    token = 'Card' + Time.now().to_f.to_s
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card twice (with same token value)
    response = Cards::create_card({:token => token, :user_token => user_token, :card_product_token => card_product_token})
    response = Cards::create_card({:token => token, :user_token => user_token, :card_product_token => card_product_token})
    response_body = JSON.parse(response.body) if response.body
    number_of_cards = JSON.parse(Cards::list_cards_for_user({:token => user_token}).body)['count']

    # Verify response
    assert_equal("201", response.code, 'Expected create_card to succeed')
    assert_equal(user_token, response_body['user_token'], 'Expected user_token to match input')
    assert_equal(card_product_token, response_body['card_product_token'], 'Expected card_product_token to match input')
    assert_equal(token, response_body['token'], 'Expected token to match input')
    assert_equal(1, number_of_cards, 'Expected only 1 card to be created')
  end

  ###########################################################################################
  #Create Card Test Case 3: invalid user_token
  ###########################################################################################
  #	Prerequisites:
  #		1. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card (passing in invalid user_token and card_product_token from prereqs)
  #		2. Repeat step 1
  #
  #	Expected:
  #		- HTTP response 400
  #		- error_code = '400010'
  #		- error_message = 'Expected create_card to succeed'
  ###########################################################################################
  test "create_card: invalid user_token" do
    user_token = 'InvalidToken' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s

    # Prereqs
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card with invalid user_token
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("400", response.code, 'Expected create_card to succeed')
    assert_equal("Cardholder not found", response_body['error_message'], 'Expected error')
    assert_equal("400010", response_body['error_code'], 'Expected error')
  end

  ###########################################################################################
  #Create Card Test Case 4: invalid bulk_issuance_token
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card (passing in invalid bulk_issuance_token, user_token from prereqs and card_product_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 400
  #		- error_code = '404160'
  #		- error_message = 'Bulk issuance request not found'
  ###########################################################################################

  test "create_card: invalid bulk_issuance_token" do
    user_token = 'InvalidToken' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s
    bulk_issuance_token = 'TestBulk' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card with invalid user_token
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token, :bulk_issuance_token => bulk_issuance_token})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("400", response.code, 'Expected create_card to succeed')
    assert_equal("Bulk issuance request not found", response_body['error_message'], 'Expected error')
    assert_equal("404160", response_body['error_code'], 'Expected error')
  end

  ###########################################################################################
  #Create Card Test Case 5: Create Digitally presented card
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card with query params show_pan and show_cvv_number = true (passing in user_token from prereqs and card_product_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 201
  #		- user_token in response matches one passed in
  #		- card_product_token in response matches one passed in
  #		- expiration matches today's month and year+4 in the format 'MMYY' => '0324'
  #		- pin_is_set is false
  #		- state is 'UNACTIVATED'
  #		- state_reason is 'New card'
  #		- fulfillment_status is 'DIGITALLY_PRESENTED'
  #		- instrument_type is 'PHYSICAL_MSR'
  #		- expedite is false
  ###########################################################################################
  test "create_card: Digitally presented card" do
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token, :show_pan => true, :show_cvv_number => true})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("201", response.code, 'Expected create_card to succeed')
    assert_equal(user_token, response_body['user_token'], 'Expected user_token to match input')
    assert_equal(card_product_token, response_body['card_product_token'], 'Expected card_product_token to match input')
    assert_equal("#{Date.today.strftime('%m')+(Date.today.strftime('%y').to_i+4).to_s}", response_body['expiration'], 'Expected expiration to be 4 years from today')
    assert_false(response_body['pin_is_set'], 'Expected pin_is_set to be false')
    assert_equal('UNACTIVATED', response_body['state'], 'Expected state to be UNACTIVATED')
    assert_equal('New card', response_body['state_reason'], 'Expected state_reason to be New card')
    assert_equal('DIGITALLY_PRESENTED', response_body['fulfillment_status'], 'Expected fulfillment_status to be ISSUED')
    assert_equal('PHYSICAL_MSR', response_body['instrument_type'], 'Expected instrument_type to be PHYSICAL_MSR')
    assert_false(response_body['expedite'], 'Expected expeditie to be false')
  end

  ###########################################################################################
  #Create Card Test Case 6: invalid token greater than 36 char
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card (passing in invalid token, user_token from prereqs and card_product_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 400
  #		- error_code = '400001'
  #		- error_message = 'Invalid input(s): token size must be between 1 and 36'
  ###########################################################################################
  test "create_card: Invalid with token > 36 char" do
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s
    long_token = 'ThisTokenIsGreaterThanThirtySixCharactersAndShouldFail'

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token, :token => long_token})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("400", response.code, 'Expected create_card to fail')
    assert_equal("Invalid input(s): token size must be between 1 and 36", response_body['error_message'], 'Expected error')
    assert_equal("400001", response_body['error_code'], 'Expected error')
  end

  ###########################################################################################
  #Create Card Test Case 7: invalid token 0 char
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card (passing in invalid token, user_token from prereqs and card_product_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 400
  #		- error_code = '400001'
  #		- error_message = 'Invalid input(s): token size must be between 1 and 36'
  ###########################################################################################
  test "create_card: Invalid with token 0 char" do
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s
    short_token = ''

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token, :token => short_token})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("400", response.code, 'Expected create_card to fail')
    assert_equal("Invalid input(s): token size must be between 1 and 36", response_body['error_message'], 'Expected error')
    assert_equal("400001", response_body['error_code'], 'Expected error')
  end

  ###########################################################################################
  #Create Card Test Case 8: Invalid with empty fulfillment
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card (passing in empty fulfillment object, user_token from prereqs and card_product_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 400
  ###########################################################################################
  test "create_card: Invalid with empty fulfillment" do
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token, :fulfillment => {}})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("400", response.code, 'Expected create_card to fail')
    #assert_equal("", response_body['error_message'], 'Expected error')
    #assert_equal("", response_body['error_code'], 'Expected error')
  end

  ###########################################################################################
  #Create Card Test Case 9: Invalid with only shipping defined in fulfillment object
  ###########################################################################################
  #	Prerequisites:
  #		1. Create User (passing in token)
  #		2. Create CardProduct (passing in token, name, start_date, and config.fulfillment.shipping.recipient_address)
  #
  #	Steps:
  #		1. Create Card (passing in fulfillment object defining shipping only, user_token from prereqs and card_product_token from prereqs)
  #
  #	Expected:
  #		- HTTP response 400
  ###########################################################################################
  test "create_card: Invalid with shipping only defined in fulfillment" do
    user_token = 'TestUser' + Time.now().to_f.to_s
    card_product_token = 'TestCardProduct' + Time.now().to_f.to_s

    # Prereqs
    Users::create_user({:token => user_token})
    CardProducts::create_card_product({
      :token => card_product_token,
      :name => card_product_token,
      :start_date => Date.today(),
      :config => {:fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}}})

    # Attempt to create card
    response = Cards::create_card({:user_token => user_token, :card_product_token => card_product_token, :fulfillment => {:shipping => {:recipient_address => Defaults::RECIPIENT_ADDRESS}}})
    response_body = JSON.parse(response.body) if response.body

    # Verify response
    assert_equal("400", response.code, 'Expected create_card to fail')
    #assert_equal("", response_body['error_message'], 'Expected error')
    #assert_equal("", response_body['error_code'], 'Expected error')
  end
end