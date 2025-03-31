# memo

import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as iam from 'aws-cdk-lib/aws-iam';
import * as path from 'path';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as cloudfrontOrigins from 'aws-cdk-lib/aws-cloudfront-origins';


export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ✅ API Gateway を作成
    const api = new apigateway.RestApi(this, 'MyApiGateway', {
      restApiName: 'MyService',
      description: 'API Gateway for Lambda',
      deployOptions: { stageName: 'prod' }, // 本番環境のステージ
    });

    // ✅ CloudFront の OAI（オリジンアクセスアイデンティティ）を作成
    const originAccessIdentity = new cloudfront.OriginAccessIdentity(this, 'OAI');

    // ✅ CloudFront を設定（API Gateway をオリジンとする）
    const cloudFrontDistribution = new cloudfront.Distribution(this, 'MyCloudFront', {
      defaultBehavior: {
        origin: new cloudfrontOrigins.HttpOrigin(`${api.restApiId}.execute-api.${this.region}.amazonaws.com`, {
          originPath: '/prod',
        }),
        allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
    });

    // ✅ API Gateway に CloudFront からのアクセスのみ許可
    const cloudFrontArn = `arn:aws:cloudfront::${this.account}:distribution/${cloudFrontDistribution.distributionId}`;
    api.addGatewayResponse('403Response', {
      type: apigateway.ResponseType.UNAUTHORIZED,
      statusCode: '403',
      responseHeaders: {
        'Access-Control-Allow-Origin': `'${cloudFrontDistribution.domainName}'`,
      },
    });

    // API Gateway のリソースポリシーを設定
    api.addToResourcePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()], // すべてのリクエストを拒否
        actions: ['execute-api:Invoke'],
        resources: [`${api.arnForExecuteApi('*', '/', '*')}`],
        conditions: {
          StringNotEquals: {
            'aws:SourceArn': `${cloudFrontArn}`, // CloudFront 以外のアクセスを拒否
          },
        },
      })
    );

    const lambdaRole = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // ✅ Lambda 関数を作成（TypeScript）
    const createLambda = (name: string) => {
      return new lambda.Function(this, name, {
        runtime: lambda.Runtime.NODEJS_22_X,
        code: lambda.Code.fromAsset(path.join(__dirname, `../src/lambda/${name}`)),
        handler: 'index.handler',
        role: lambdaRole,
      });
    };

    const hoge01Lambda = createLambda('hoge01');
    const hoge02Lambda = createLambda('hoge02');

    // ✅ Lambda との統合
    const createLambdaIntegration = (lambdaFunction: lambda.Function) =>
      new apigateway.LambdaIntegration(lambdaFunction, { proxy: true });

    const hoge01LambdaIntegration = createLambdaIntegration(hoge01Lambda);
    const hoge02LambdaIntegration = createLambdaIntegration(hoge02Lambda);

    // ✅ /read に readLambda を割り当て
    const hoge01Resource = api.root.addResource('hoge01');
    hoge01Resource.addMethod('GET', hoge01LambdaIntegration);

    // ✅ /edit に editLambda を割り当て
    const hoge02Resource = api.root.addResource('hoge02');
    hoge02Resource.addMethod('GET', hoge02LambdaIntegration);

    
    
  }
}
