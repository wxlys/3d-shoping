<template>
  <div>
    <!-- <div class="open-image" v-db-click @click="clear" v-if="openImage">
      <img src="@/assets/images/wechat_demo.png" alt="" />
    </div> -->
    <!--小方块-->
    <grid-menu v-if="userInfo.level == 0" />
    <!--3D打印业务统计-->
    <print-dashboard />
    <!--版本升级-->
    <!-- <upgrade v-if="force_reminder == 1" /> -->
  </div>
</template>

<script>
import gridMenu from './components/gridMenu';
import printDashboard from './components/printDashboard';
import { auth } from '@/api/system';
import { mapState } from 'vuex';
export default {
  name: 'index',
  components: {
    gridMenu,
    printDashboard,
  },
  data() {
    return {
      openImage: false,
      visitType: 'day', // day, month, year
      visitDate: [new Date(), new Date()],
      force_reminder: null,
    };
  },
  computed: {
    ...mapState('userInfo', ['userInfo']),
  },
  mounted() {
    this.getAuth();
  },
  methods: {
    getAuth() {
      auth()
        .then((res) => {
          let data = res.data || {};
          this.force_reminder = data.force_reminder;
          if (data.auth_code && data.auth) {
            this.authCode = data.auth_code;
            this.auth = true;
          }
          this.openImage = true;
        })
        .catch((res) => {});
    },
    clear() {
      this.openImage = false;
    },
  },
};
</script>

<style lang="scss">
.dashboard-console-visit {
  .ivu-radio-group-button .ivu-radio-wrapper {
    border: none !important;
    box-shadow: none !important;
    padding: 0 12px;
  }
  .ivu-radio-group-button .ivu-radio-wrapper:before,
  .ivu-radio-group-button .ivu-radio-wrapper:after {
    display: none;
  }
}
.open-image {
  transition: none;
  animation: none;
  display: flex;
  align-items: center;
  justify-content: center;
  position: fixed;
  background-color: rgba(0, 0, 0, 0.6);
  height: 100vh;
  width: 100vw;
  top: 0;
  left: 0;
  z-index: 1000;
  img {
    width: 800px;
  }
}
</style>
