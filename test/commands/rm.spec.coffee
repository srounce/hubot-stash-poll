# test framework
expect = require('chai').expect

# dependencies/helpers
helpers = require('../helpers')
testContext = require('../test_context')

# test target
bot = require('../../src/scripts/bot')


describe 'bot | commands | rm', ->
  context = {}

  beforeEach (done) ->
    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user
      bot(context.robot)
      done()

  afterEach ->
    context.sandbox.restore()


  # =========================================================================
  #  INTERNAL TEST HELPERS
  # =========================================================================
  whenRemoving = (api_url, expectCallback) ->
    message = "stash-poll rm #{api_url}"

    helpers.onRobotReply context.robot, context.user, message, (replyData) ->
      replyData.referencedRepo =
        context.robot.brain.data['stash-poll']?[api_url]

      expectCallback(replyData)


  # =========================================================================
  #  LISTENER
  # =========================================================================
  it 'should register a listener', ->
    # given
    stub = context.robot.respond.withArgs(/stash-poll rm (.*)/i)

    # then
    expect(stub.calledOnce).to.equal true


  # =========================================================================
  #  NON-EMPTY BRAIN
  # =========================================================================
  describe 'given a non-empty brain', ->
    it 'should unsubscribe the room from the given repo', ->
      # given
      helpers.brainFor(context.robot)
        .repo('http://mocha.com/', ['#mocha', '#abc'])

      expected = '#mocha is no longer subscribing to PR changes in repo ' +
                 'http://mocha.com/'

      # then
      whenRemoving 'http://mocha.com/', ({referencedRepo, envelope, strings}) ->
        expect(referencedRepo.rooms).to.eql ['#abc']
        expect(strings[0]).to.equal expected
