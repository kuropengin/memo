import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as cloudfrontOrigins from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';
import { LambdaFunctions } from './lambda-functions';

export class ApiGateway extends Construct {
  public readonly cloudFrontDistribution: cloudfront.Distribution;

  constructor(scope: Construct, id: string, lambdaFunctions: LambdaFunctions) {
    super(scope, id);

    // ✅ API Gateway を作成
    const api = new apigateway.RestApi(this, 'MyApiGateway', {
      restApiName: 'MyService',
      description: 'API Gateway for Lambda',
      deployOptions: { stageName: 'prod' },
    });

    // ✅ Lambda との統合
    const readLambdaIntegration = new apigateway.LambdaIntegration(lambdaFunctions.readLambda, { proxy: true });
    const editLambdaIntegration = new apigateway.LambdaIntegration(lambdaFunctions.editLambda, { proxy: true });

    // ✅ /read に readLambda を割り当て
    const readResource = api.root.addResource('read');
    readResource.addMethod('GET', readLambdaIntegration);

    // ✅ /edit に editLambda を割り当て
    const editResource = api.root.addResource('edit');
    editResource.addMethod('POST', editLambdaIntegration);

    // ✅ CloudFront の OAI を作成
    const originAccessIdentity = new cloudfront.OriginAccessIdentity(this, 'OAI');

    // ✅ CloudFront を設定（API Gateway をオリジンとする）
    this.cloudFrontDistribution = new cloudfront.Distribution(this, 'MyCloudFront', {
      defaultBehavior: {
        origin: new cloudfrontOrigins.HttpOrigin(`${api.restApiId}.execute-api.${this.node.tryGetContext('region')}.amazonaws.com`, {
          originPath: '/prod',
        }),
        allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
    });

    // ✅ API Gateway に CloudFront からのアクセスのみ許可
    const cloudFrontArn = `arn:aws:cloudfront::${this.node.tryGetContext('account')}:distribution/${this.cloudFrontDistribution.distributionId}`;
    api.addGatewayResponse('403Response', {
      type: apigateway.ResponseType.UNAUTHORIZED,
      statusCode: '403',
      responseHeaders: {
        'Access-Control-Allow-Origin': `'${this.cloudFrontDistribution.domainName}'`,
      },
    });
  }
}
