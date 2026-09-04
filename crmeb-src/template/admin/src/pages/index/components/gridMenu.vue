<template>
  <el-row :gutter="16" class="dashboard-console-grid">
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-user-user-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/user/list' }">
          <div class="icon">
            <i class="iconfont iconyonghuguanli" style="color: #0256ff"></i>
          </div>
          <p>用户管理</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['setting-system-config']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/setting/system_config' }">
          <div class="icon">
            <i class="iconfont iconxitongshezhi" style="color: #9fdb1d"></i>
          </div>
          <p>系统设置</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-store-storeProuduct-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/product/product_list' }">
          <div class="icon">
            <i class="iconfont iconshangpin" style="color: #0fc6c2"></i>
          </div>
          <p>商品</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-order-storeOrder-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/order/list' }">
          <div class="icon">
            <i class="iconfont icondingdanguanli" style="color: #b37feb"></i>
          </div>
          <p>订单管理</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-store-storeCategory-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/product/product_classify' }">
          <div class="icon">
            <i class="iconfont iconfenlei" style="color: #f7ba1e"></i>
          </div>
          <p>商品分类</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-order-print-inquiry-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/order/inquiry' }">
          <div class="icon">
            <i class="iconfont iconxiaoxi" style="color: #7da2ff"></i>
          </div>
          <p>询价管理</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-order-print-queue-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/order/print-queue' }">
          <div class="icon">
            <i class="iconfont iconshijian" style="color: #ff7d00"></i>
          </div>
          <p>排单管理</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['setting-merchant-system-verify-order']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/setting/merchant/system_verify_order/index' }">
          <div class="icon">
            <i class="iconfont iconsaoma" style="color: #0fc6c2"></i>
          </div>
          <p>核销记录</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['cms-article-index']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/cms/article/index' }">
          <div class="icon">
            <i class="iconfont iconwenzhangguanli" style="color: #7da2ff"></i>
          </div>
          <p>打印指南</p>
        </router-link>
      </el-card>
    </el-col>
    <el-col v-bind="grid" class="ivu-mb" v-auth="['admin-setting-pages-devise']">
      <el-card shadow="never">
        <router-link :to="{ path: $routeProStr + '/setting/pages/devise/0' }">
          <div class="icon">
            <i class="iconfont iconzhuangxiu" style="color: #f56a00"></i>
          </div>
          <p>首页装修</p>
        </router-link>
      </el-card>
    </el-col>
  </el-row>
</template>
<script>
export default {
  data() {
    return {
      grid: {
        xl: 3,
        lg: 3,
        md: 6,
        sm: 6,
        xs: 12,
      },
    };
  },
};
</script>
<style lang="scss" scoped>
.dashboard-console-grid {
  text-align: center;
  .ivu-card-body {
    padding: 0;
  }
  .icon {
    width: 48px;
    height: 48px;
    background-color: #f6f6f6;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  i {
    font-size: 24px;
  }
  a {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    color: inherit;
    padding: 16px;
  }
  p {
    margin-top: 8px;
    font-size: 14px;
    font-weight: 400;
    color: #333333;
    line-height: 22px;
    white-space: nowrap;
  }
}
</style>
